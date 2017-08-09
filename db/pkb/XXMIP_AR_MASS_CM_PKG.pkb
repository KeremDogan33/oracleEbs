CREATE OR REPLACE PACKAGE BODY APPS.XXMIP_AR_MASS_CM_PKG    as

    Procedure   concurrent_transaction (
                                errbuff out varchar2,
                                retcode out varchar2,
                                p_header_id in  number,
                                p_responsibility_id in  number,
                                p_function_param    in  varchar2
    )   is
        
    l_param_status  varchar2(50);
    l_param_msg     varchar2(150);
                       
    l_request_id    number;
        
    cursor  paper_numbers   is
        select   
            CM_PAPER_NUMBER            
        from
            XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
        where
            header_id   =   p_header_id                        
            and (NVL(is_processed,'N')   =   'N' or (is_processed=  'Y' and NVL(success_flag,'E')    =   'E'))
        group   by
            CM_PAPER_NUMBER;
                                
    cursor  trx_numbers (   p_cm_paper_number      in   varchar2) is
        select   
            header_id,        
            trx_number,
            sob,            
            null    as  API_MSG,
            null    as  IS_PROCESSED,
            null    as  SUCCESS_FLAG,
            CUSTOMER_TRX_ID,
            CM_TRX_ID            
        from
            XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
        where
            header_id   =   p_header_id                        
            and (NVL(is_processed,'N')   =   'N' or (is_processed=  'Y' and NVL(success_flag,'E')    =   'E'))
            and cm_paper_number =    p_cm_paper_number 
        group   by
            trx_number,
            sob,                        
            CUSTOMER_TRX_ID,
            CM_TRX_ID,
            header_id;       
        
    type    transaction_rows    is  table   of  trx_numbers%ROWTYPE    INDEX BY PLS_INTEGER;    
    l_transactions  transaction_rows;    

    l_number_of_error_trx   number;
    l_interface_tbl APPS.XXMIP_GLOBAL_XLS_UTIL_PKG.interface_line_status_tbl_type;      
    
    Begin                               
            
        l_request_id    :=  fnd_global.CONC_REQUEST_ID;
        fnd_file.put_line(fnd_file.log,'REQUEST_ID: '||l_request_id);
                        
        XXMIP_GLOBAL_XLS_UTIL_PKG.set_header_process_status (p_header_id,l_request_id,'E'); --  set is_processed    executing
        
        XXMIP_AR_MASS_CM_PKG.CHECK_FILE (
                                        ERRBUFF             =>  l_param_msg,
                                        RETCODE             =>  l_param_status,
                                        P_HEADER_ID         =>  p_header_id,
                                        P_RESPONSIBILITY_ID =>  p_responsibility_id,
                                        P_FUNCTION_PARAM    =>  p_function_param
        );
                                
        if  (   l_param_status   <>   '0'    )    then        
            
            fnd_file.put_line(fnd_file.log,'CHECK_FILE_STATUS: '||l_param_status);
        
            retcode :=  l_param_status;  --  ERROR
            errbuff :=  l_param_msg;                          
            
            XXMIP_GLOBAL_XLS_UTIL_PKG.set_header_process_status   (p_header_id,l_request_id,'N');
            
        else    --  passed header   validation                                       
            
            for sel in  paper_numbers   loop
                
                fnd_file.put_line(fnd_file.log,'paper_number: '||sel.cm_paper_number);
            
                l_number_of_error_trx   :=  0;
                open    trx_numbers(sel.cm_paper_number);
                loop
                    
                    fetch   trx_numbers   bulk    collect into    l_transactions  limit   1000;
                    exit    when    l_transactions.COUNT =   0; 
                    
                    for i   in  1   ..  l_transactions.COUNT    loop
                                   
                        Begin                    
                            select  customer_trx_id into
                                l_transactions(i).customer_trx_id
                            from    
                                apps.ra_customer_trx_all rt 
                            where   
                                trx_number  =   l_transactions(i).TRX_NUMBER  
                                and set_of_books_id     =   l_transactions(i).SOB
                                and cust_trx_type_id    =   decode(l_transactions(i).SOB,1001,1000,1003,1027)    --  invoice,marine invoice;    --  invoice     
                                and exists  (
                                    select  1   from
                                        apps.ra_customer_trx_lines_all lin
                                    where
                                        lin.customer_trx_id =   rt.customer_trx_id
                                        and line_type   =   'LINE'
                                );
                                                             
                        End;
                             
                        fnd_file.put_line(fnd_file.log,'Calling Api With parameters: '||l_transactions(i).trx_number||' '||l_transactions(i).SOB||' '||l_transactions(i).header_id);
                        credit_invoice  (
                            x_api_status    =>  l_transactions(i).SUCCESS_FLAG,
                            x_message       =>  l_transactions(i).API_MSG,
                            x_credit_trx_id =>  l_transactions(i).CM_TRX_ID,
                            p_trx_number    =>  l_transactions(i).trx_number,
                            p_sob_id        =>  l_transactions(i).SOB,
                            p_header_id     =>  l_transactions(i).header_id                           
                        ) ;                                        
                        if  (l_transactions(i).SUCCESS_FLAG   <>  'S')    then
                            
                            l_number_of_error_trx   :=  l_number_of_error_trx   +   1;
                        
                        end if;
                        
                        fnd_file.put_line(fnd_file.log,'Result: '||l_transactions(i).SUCCESS_FLAG);
                        fnd_file.put_line(fnd_file.log,'API_MSG: '||l_transactions(i).API_MSG);
                        
                    end loop;
                    
                    FORALL  x   in  l_transactions.first  ..  l_transactions.last
                        update  
                            XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
                        set
                            CUSTOMER_TRX_ID =   l_transactions(x).CUSTOMER_TRX_ID,
                            IS_PROCESSED    =   'Y',--l_transactions(x).IS_PROCESSED,
                            LAST_UPDATE_DATE    =   SYSDATE,
                            CM_TRX_ID   =   l_transactions(x).CM_TRX_ID,   
                            SUCCESS_FLAG    =   l_transactions(x).SUCCESS_FLAG,
                            API_MSG         =   l_transactions(x).API_MSG   
                        where
                            header_id       =   l_transactions(x).header_id        
                            and trx_number  =   l_transactions(x).trx_number
                            and sob         =   l_transactions(x).sob;
                    
                                                                               
                        select
                            header_id,
                            INTERFACE_LINE_ID,
                            SUCCESS_FLAG,
                            API_MSG
                        bulk    collect into    l_interface_tbl    
                        from
                            XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
                        where
                            header_id   =   p_HEADER_ID
                            and CM_PAPER_NUMBER    =   sel.cm_paper_number;
                        
                        XXMIP_GLOBAL_XLS_UTIL_PKG.set_lines_status(p_lines_result   =>  l_interface_tbl);
                                        
                end loop;
                close   trx_numbers;   
                                                                                
                if  (   l_number_of_error_trx    >   0  )   then
                    rollback;
                else
                    commit;
                end if;
                
            end loop;
            
            XXMIP_GLOBAL_XLS_UTIL_PKG.set_header_process_status   (p_header_id,l_request_id,'Y');
            
            /*
            open    trx_numbers; 
            loop
                
                fetch   trx_numbers   bulk    collect into    l_transactions  limit   250;
                exit    when    l_transactions.COUNT =   0;   
                
                for i   in  1   ..  l_transactions.COUNT    
                loop                                                        
                
                    Begin                    
                        select  customer_trx_id into
                            l_transactions(i).customer_trx_id
                        from    
                            apps.ra_customer_trx_all rt 
                        where   
                            trx_number  =   l_transactions(i).TRX_NUMBER  
                            and set_of_books_id     =   l_transactions(i).SOB
                            and cust_trx_type_id    =   decode(l_transactions(i).SOB,1001,1000,1003,1027)    --  invoice,marine invoice;    --  invoice     
                            and exists  (
                                select  1   from
                                    apps.ra_customer_trx_lines_all lin
                                where
                                    lin.customer_trx_id =   rt.customer_trx_id
                                    and line_type   =   'LINE'
                            );
                                                             
                    End;
                        
                    if  (   l_transactions(i).customer_trx_id    is  not null   )   then
                                                                                                        
                        
                        SELECT  
                            NVL(SUM(ARA.amount_applied),0)   into    l_pay_check     
                        FROM 
                            apps.AR_RECEIVABLE_APPLICATIONS_ALL ARA, 
                            apps.AR_CASH_RECEIPTS_ALL ACR, 
                            apps.RA_CUSTOMER_TRX_ALL RCT 
                        WHERE 
                            ARA.STATUS  ='APP' 
                            AND ARA.CASH_RECEIPT_ID=ACR.CASH_RECEIPT_ID 
                            AND ARA.APPLIED_CUSTOMER_TRX_ID=RCT.CUSTOMER_TRX_ID
                            AND RCT.customer_trx_id =   l_transactions(i).CUSTOMER_TRX_ID;
                        
                        if  (   l_pay_check <>   0   )  then -- Eþleme ters çevrilince koþula uymuyor. 31032017                                                            
                        
                            l_transactions(i).IS_PROCESSED      :=  'Y';
                            l_transactions(i).SUCCESS_FLAG      :=  'E';
                            l_transactions(i).API_MSG           :=  'ÝÞLEM NUMARASINA AÝT EÞLEME KAYDI BULUNMAKTADIR';
                            l_transactions(i).CM_TRX_ID         :=  null;    
                                
                            l_error_transactions (l_error_transactions.COUNT + 1) :=    l_transactions (i);
                                
                        else                                    
                                                        
                                                        
                            if  (   check_currency_per_trx (
                                                            l_transactions(i).trx_number,
                                                            l_transactions(i).sob,
                                                            l_transactions(i).header_id
                                                            )  =   'S'
                            )   then
                                                                        
                                l_validated_transactions    (l_validated_transactions.COUNT +   1)  :=  l_transactions (i);                                                                                                                                
                                
                            else
                                
                                l_transactions(i).IS_PROCESSED      :=  'Y';
                                l_transactions(i).SUCCESS_FLAG      :=  'E';
                                l_transactions(i).API_MSG           :=  'ÝÞLEM ÝLE XLS DOSYASI ARASINDA KUR FARKI BULUNMAKTADIR';
                                l_transactions(i).CM_TRX_ID         :=  null;    
                                  
                                l_error_transactions (l_error_transactions.COUNT + 1) :=    l_transactions (i);
                                
                            end if;
                        end if;                                                                                
                    end if;                                                                                                                            
                end loop;                                                      
                
                for i   in  1   ..  l_validated_transactions.COUNT  loop
                    fnd_file.put_line(fnd_file.log,'Calling Api With parameters: '||l_validated_transactions(i).trx_number||' '||l_validated_transactions(i).SOB||' '||l_validated_transactions(i).header_id);
                    credit_invoice  (
                        x_api_status    =>  l_validated_transactions(i).SUCCESS_FLAG,
                        x_message       =>  l_validated_transactions(i).API_MSG,
                        x_credit_trx_id =>  l_validated_transactions(i).CM_TRX_ID,
                        p_trx_number    =>  l_validated_transactions(i).trx_number,
                        p_sob_id        =>  l_validated_transactions(i).SOB,
                        p_header_id     =>  l_validated_transactions(i).header_id                           
                    ) ;
                
                end loop;
                
                FORALL  x   in  l_validated_transactions.first  ..  l_validated_transactions.last
                        update  
                            XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
                        set
                            CUSTOMER_TRX_ID =   l_validated_transactions(x).CUSTOMER_TRX_ID,
                            IS_PROCESSED    =   'Y',
                            LAST_UPDATE_DATE    =   SYSDATE,
                            SUCCESS_FLAG    =   l_validated_transactions(x).SUCCESS_FLAG,
                            API_MSG         =   l_validated_transactions(x).API_MSG,
                            CM_TRX_ID       =   l_validated_transactions(x).CM_TRX_ID   
                        where
                            header_id       =   l_validated_transactions(x).header_id        
                            and trx_number  =   l_validated_transactions(x).trx_number
                            and sob         =   l_validated_transactions(x).sob;
                
                FORALL  x   in  l_error_transactions.first  ..  l_error_transactions.last
                        update  
                            XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
                        set
                            CUSTOMER_TRX_ID =   l_error_transactions(x).CUSTOMER_TRX_ID,
                            IS_PROCESSED    =   l_error_transactions(x).IS_PROCESSED,
                            LAST_UPDATE_DATE    =   SYSDATE,
                            SUCCESS_FLAG    =   l_error_transactions(x).SUCCESS_FLAG,
                            API_MSG         =   l_error_transactions(x).API_MSG   
                        where
                            header_id       =   l_error_transactions(x).header_id        
                            and trx_number  =   l_error_transactions(x).trx_number
                            and sob         =   l_error_transactions(x).sob;                                                                                                                                                                               
                                                                                                                                                                                                                
                for i   in  1   ..  l_transactions.COUNT    LOOP                                        
                    
                    select
                        l_transactions(i).header_id,
                        INTERFACE_LINE_ID,
                        SUCCESS_FLAG,
                        API_MSG
                    bulk    collect into    l_interface_tbl    
                    from
                        XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
                    where
                        header_id   =   l_transactions(i).HEADER_ID
                        and sob =   l_transactions(i).SOB
                        and trx_number  =   l_transactions(i).TRX_NUMBER;
                    
                    XXMIP_GLOBAL_XLS_UTIL_PKG.set_lines_status(p_lines_result   =>  l_interface_tbl);
                    
                end loop;
                
            end loop;                                 
            close   trx_numbers;                                                                
                               
            
            */
        end if;                                
                                                      
    End concurrent_transaction;            
        
    function    check_currency_per_trx (
        p_trx_number    in  varchar2,
        p_sob_id        in  number,
        p_header_id in  number
    )   return  varchar2    is
            
    cursor  trx_number   is
    select                
        trx_number,
        NVL(sob,1001)   as  sob
    from
        XXMIP_CREDIT_MEMO_INTERFACE
    where
        header_id   =   p_header_id
        and trx_number  =   p_trx_number
        and sob =   p_sob_id
    group   by  trx_number,sob; 
            
    cursor  lines   is
    select
        CM_CURRENCY_RATE
    from
        XXMIP_CREDIT_MEMO_INTERFACE
    where
        header_id   =   p_header_id
        and trx_number  =   p_trx_number
        and sob =   p_sob_id;    
    
    l_inv_cur   ra_customer_Trx_all.invoice_currency_code%TYPE;
    l_custom_rate   ra_customer_trx_all.attribute4%TYPE;        
    
    l_result    varchar2(1);
    
    Begin
                    
        for sel   in  trx_number   loop
                                    
            l_result    :=  'S';
        
            Begin
                    
                select
                    invoice_currency_code,replace(attribute4,',','.')  
                    into l_inv_cur,l_custom_rate                        
                from        
                    ra_customer_trx_all
                where
                    trx_number  =   sel.trx_number
                    and set_of_books_id =   sel.sob;
                
                if  (   l_inv_cur    =   'TRY'  )  then
                    
                    for indx    in  lines   loop
                    
                        if  (   l_custom_rate   <>  to_char(indx.cm_currency_rate)   )    then
                        
                            l_result    :=   'E';
                            exit;
                        
                        end if;     
                    
                    end loop;
                                                                                                                            
                end if;
            
            End ;                        
        
        end loop;
            
        return  l_result; 
        
    End check_currency_per_trx;         
    
    function    get_memo_trx_id (p_request_id   in  number) return  number  is
    
    l_cm_trx_id   ra_cm_requests_all.cm_customer_trx_id%type;
        
    begin
        
        select cm_customer_trx_id
            into l_cm_trx_id
        from 
            ra_cm_requests_all
        where 
            cm_customer_trx_id is not null
            and request_id = p_request_id;

        return l_cm_trx_id;
    exception
        when others then
        return 0;
    
    End get_memo_trx_id; 
    
    procedure   credit_invoice  (
            x_api_status        out varchar2,
            x_message           out varchar2,
            x_credit_trx_id     out number,
            p_trx_number   in  varchar2,
            p_sob_id    in  number,
            p_header_id in  number                       
    )   is        
    
    l_cm_lines_tbl              arw_cmreq_cover.cm_line_tbl_type_cover;        
    l_attribute_rec             arw_cmreq_cover.pq_attribute_rec_type;
    l_interface_attribute_rec   arw_cmreq_cover.pq_interface_rec_type;   
              
    v_return_status     varchar2 (1);
    v_msg_count         number;
    v_msg_data          varchar2 (2400);
    v_request_id        number;
        
    l_cm_trx_date   date;            
    l_cm_note   varchar2(4000); 
    l_cm_paper_number   varchar2(500);
    l_efat_ff   varchar2(500);
    l_cm_currency_rate  number;
    l_cm_currency_rate_date date;
    
    l_period_name   varchar2(50);
    l_trx_currency_code varchar2(50);
    
    l_org_id    number;    
    l_customer_trx_id   number;                       
    
    l_batch_source_name varchar2(4000);
    
    p_count number;    
    
    cursor  line_records    is
    select
        TRX_LINE_NUM,
        CM_LINE_DESC,
        CM_LINE_ITEM,
        QUANTITY,
        UNIT_PRICE,
        xls.TRX_NUMBER,
        SOB,
        rctl.customer_trx_line_id,
        to_number(null) as  memo_line_id,
        to_number(null) as  cm_trx_line_id,
        to_number(null) as  cm_trx_line_ccid
    from
        XXMIP.XXMIP_CREDIT_MEMO_INTERFACE   xls,
        ra_customer_trx_lines_all   rctl,
        ra_customer_trx_all rct
    where
        rctl.customer_trx_id    =   rct.customer_trx_id
        and rct.trx_number  =   xls.trx_number
        and rct.set_of_books_id =   xls.sob
        and rctl.line_number    =   xls.trx_line_num
        and rctl.line_type  =   'LINE'
        and xls.trx_number      =   p_trx_number
        and xls.sob         =   p_sob_id   
        and xls.header_id   =   p_header_id;
                          
    type    lines    is  table   of  line_records%ROWTYPE    INDEX BY PLS_INTEGER;    
    l_transactions  lines;
    
    Begin
                                                                                                               
        Begin
            select                  
                bs.name,
                ra.org_id,
                ra.customer_trx_id,
                ra.invoice_currency_code               
            into                    
                l_batch_source_name,
                l_org_id,
                l_customer_trx_id,
                l_trx_currency_code               
            from 
                ra_customer_trx_all     ra,
                ra_batch_sources_all    bs
            where   
                trx_number = p_trx_number
                and set_of_books_id =   p_sob_id
                and ra.batch_source_id  =   bs.batch_source_id
                and ra.org_id   =   bs.org_id;
        exception   when    others  then
            x_api_status    :=  fnd_api.g_ret_sts_error;
            x_message       :=  'Error Getting Batch Source Name';
            x_credit_trx_id :=  null; 
            return;               
        End;
    
        Begin                        
            MO_GLOBAL.SET_POLICY_CONTEXT('S', l_org_id);        
        End;
        
        Begin
            select
                distinct    
                    trunc(cm_trx_date),
                    cm_note,
                    cm_paper_number,
                    cm_currency_rate,
                    NVL(trunc(CM_RATE_DATE),trunc(cm_trx_date))
                into
                    l_cm_trx_date,
                    l_cm_note,
                    l_cm_paper_number,
                    l_cm_currency_rate,
                    l_cm_currency_rate_date       
            from
                XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
            where
                trx_number      =   p_trx_number
                and sob         =   p_sob_id
                and header_id   =   p_header_id;    
        end;                
                
        if  (length(l_cm_paper_number)  <   16) then
            
            l_efat_ff   :=  null;
            
        else
            
            l_efat_ff   :=  l_cm_paper_number;

        end if;
        
        select
            attribute_category,
            attribute1,
            attribute2,             --  period
            l_cm_paper_number,      --  matbuu  no
            l_cm_currency_rate,     --  kur
            attribute5,
            attribute6,
            null,   --  teslim alan
            null,   --  teslim tarihi
            attribute9,
            l_efat_ff,      --  efa yerine matbuu   no
            l_cm_note,              --  iade    notu
            attribute12,
            attribute13,
            attribute14,
            attribute15,
            INTERFACE_HEADER_CONTEXT,
            INTERFACE_HEADER_ATTRIBUTE1,
            INTERFACE_HEADER_ATTRIBUTE2,
            INTERFACE_HEADER_ATTRIBUTE3,
            INTERFACE_HEADER_ATTRIBUTE4,
            INTERFACE_HEADER_ATTRIBUTE5,
            INTERFACE_HEADER_ATTRIBUTE6,
            INTERFACE_HEADER_ATTRIBUTE7,
            INTERFACE_HEADER_ATTRIBUTE8,
            INTERFACE_HEADER_ATTRIBUTE9,
            INTERFACE_HEADER_ATTRIBUTE10,
            INTERFACE_HEADER_ATTRIBUTE11,
            INTERFACE_HEADER_ATTRIBUTE12,
            INTERFACE_HEADER_ATTRIBUTE13,
            INTERFACE_HEADER_ATTRIBUTE14,
            INTERFACE_HEADER_ATTRIBUTE15            
        into
            l_attribute_rec.attribute_category,
            l_attribute_rec.attribute1,
            l_attribute_rec.attribute2,
            l_attribute_rec.attribute3,
            l_attribute_rec.attribute4,
            l_attribute_rec.attribute5,
            l_attribute_rec.attribute6,
            l_attribute_rec.attribute7,
            l_attribute_rec.attribute8,
            l_attribute_rec.attribute9,
            l_attribute_rec.attribute10,
            l_attribute_rec.attribute11,
            l_attribute_rec.attribute12,
            l_attribute_rec.attribute13,
            l_attribute_rec.attribute14,
            l_attribute_rec.attribute15,
            l_interface_attribute_rec.INTERFACE_HEADER_CONTEXT,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE1,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE2,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE3,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE4,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE5,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE6,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE7,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE8, 
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE9,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE10, 
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE11,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE12, 
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE13,
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE14, 
            l_interface_attribute_rec.INTERFACE_HEADER_ATTRIBUTE15                    
        from
            ra_customer_trx_all
        where
            customer_trx_id =   l_customer_trx_id;                        
        
        XXMIP_AR_MASS_CM_PKG.validate_lines (
                x_status        =>  x_api_status, 
                x_error_msg     =>  x_message,       
                p_trx_number    =>  p_trx_number,                        
                p_sob_id        =>  p_sob_id,
                p_header_id     =>  p_header_id
        ); 
        
        if  (   x_api_status   =   fnd_api.G_RET_STS_SUCCESS  )    then
                        
            open    line_records;   --  1   HEADER  AT  A   TIME
            loop
                fetch   line_records bulk    collect into   l_transactions  limit   500;                  
                exit    when    l_transactions.COUNT    =   0; 
            
                for i   in  1   ..  l_transactions.COUNT    loop
                                    
                    l_cm_lines_tbl (i).customer_trx_line_id :=  l_transactions(i).customer_trx_line_id;
                    l_cm_lines_tbl (i).quantity_credited    :=  l_transactions(i).QUANTITY  *-1;
                    l_cm_lines_tbl (i).price                :=  round(l_transactions(i).UNIT_PRICE *-1,2)  ;                                      
                    l_cm_lines_tbl (i).extended_amount      :=  round(l_transactions(i).QUANTITY * l_transactions(i).UNIT_PRICE,2);                                        

                end loop; 
            
            end loop;
            close   line_records; 
        
        else        
            return;                                
        end if;
        
        if  (   l_cm_lines_tbl.COUNT =   0)  then
                
            x_api_status    :=  fnd_api.g_ret_sts_error;
            x_message       :=  'SATIR NO BULUNAMADI';
            x_credit_trx_id :=  null; 
            return;
        
        end if;    
        
        fnd_msg_pub.initialize;
        ar_credit_memo_api_pub.create_request   (   
                                                p_api_version                   => 1.0
                                                ,p_init_msg_list                => fnd_api.g_true
                                                ,p_commit                       => fnd_api.g_false
                                                ,p_customer_trx_id              => l_customer_trx_id
                                                ,p_line_credit_flag             => 'Y'
                                                ,p_cm_line_tbl                  =>  l_cm_lines_tbl
                                                ,p_cm_reason_code               =>  'RETURN'  --  iade   fatura
                                                ,p_skip_workflow_flag           =>  'Y'
                                                ,p_batch_source_name            =>  l_batch_source_name                                                                                               
                                                ,p_credit_method_installments   =>  null
                                                ,p_credit_method_rules          =>  null
                                                ,x_return_status                =>  v_return_status
                                                ,x_msg_count                    =>  v_msg_count
                                                ,x_msg_data                     =>  v_msg_data
                                                ,x_request_id                   =>  v_request_id
                                                ,p_attribute_rec                =>  l_attribute_rec
                                                --,p_interface_attribute_rec      =>  l_interface_attribute_rec
                                                ,p_gl_date                      =>  l_cm_trx_date                                                      
        );
                                    
        if  v_return_status <> fnd_api.g_ret_sts_success    then
            
            if  v_msg_count = 1  then                
            
                x_api_status    :=  fnd_api.g_ret_sts_error;
                x_message       :=  v_msg_data; 
                rollback;               
                return;
                            
            elsif v_msg_count > 1   then    
                
                loop
                    p_count       :=    p_count + 1;
                    v_msg_data    :=    fnd_msg_pub.get (fnd_msg_pub.g_next, fnd_api.g_false);

                    if v_msg_data is null   then
                        exit;
                    end if;

                    x_message     :=
                    x_message
                    || 'Message'
                    || p_count
                    || ' ---'
                    || v_msg_data
                    || chr (10);
                end loop;

                x_message    := rtrim (x_message, chr (10));
                                
            end if;
            
            x_api_status    := fnd_api.g_ret_sts_error;            /*1.5.10.0.1*/
            rollback;            
        
        else                        
        
            x_credit_trx_id := get_memo_trx_id (v_request_id);                                                      
            
            if  x_credit_trx_id = 0  then
                x_api_status        :=  fnd_api.g_ret_sts_error;
                x_message           :=  'Request_id : '|| v_request_id|| ' '|| ' , No cm_trx_id found RA_CM_REQUESTS_ALL';
                rollback;
                return;
            end if;
                                                                              
            update  
                ra_customer_trx_all 
            set                 
                trx_date   =   l_cm_trx_date       
            where   
                customer_trx_id =   x_credit_trx_id;                                                                                          
            
            update  
                ar_payment_schedules_all
            set
                trx_date   =   l_cm_trx_date       
            where
                customer_trx_id =   x_credit_trx_id;      

            if  (   l_trx_currency_code  <>  'TRY'  )  then
               
                update  ra_customer_trx_all
                set
                    exchange_rate_type  =   'User',
                    exchange_rate   =   l_cm_currency_rate,                    
                    exchange_date   =   l_cm_currency_rate_date
                where
                    customer_trx_id =   x_credit_trx_id;
                
                /*  24.06.2017  Currency    Rate    Update  */    
                update  ar_payment_schedules_all
                set
                    acctd_amount_due_remaining  =   round(amount_due_original *   l_cm_currency_rate,2),
                    exchange_rate   =   l_cm_currency_rate,
                    exchange_date   =   l_cm_currency_rate_date      
                where
                    customer_trx_id =   x_credit_trx_id;      
                                                                      
                /*  24.06.2017  Currency    Rate    Update  */                
                update  
                    RA_CUST_TRX_LINE_GL_DIST_ALL
                set 
                    ACCTD_AMOUNT =   round(AMOUNT   *   l_cm_currency_rate,2)   
                where
                    customer_trx_id    =   x_credit_trx_id;

            end if;

            open    line_records;   --  1   HEADER  AT  A   TIME
            loop
                fetch   line_records bulk    collect into   l_transactions  limit   500;                  
                exit    when    l_transactions.COUNT    =   0;                             
                
                for indx    in  1   ..  l_transactions.COUNT    loop
                    
                    Begin
                    
                        select
                            customer_trx_line_id    into    l_transactions(indx).cm_trx_line_id    
                        from
                            ra_customer_trx_lines_all
                        where
                            customer_trx_id =   x_credit_trx_id
                            and line_number =   l_transactions(indx).TRX_LINE_NUM
                            and line_type   =   'LINE';                                                   
                    End;
                
                    get_item_memo (
                        x_memo_line_id      =>  l_transactions(indx).memo_line_id,
                        p_item_description  =>  l_transactions(indx).CM_LINE_DESC
                    );
                    
                    select
                        GL_ID_REV   into    l_transactions(indx).cm_trx_line_ccid
                    from
                        ar_memo_lines_all_b                                
                    where
                        memo_line_id    =   l_transactions(indx).memo_line_id;
                    
                end loop;
                
                forall  i   in  1   ..  l_transactions.COUNT                                         
                update    ra_customer_trx_lines_all   rctl2
                set description     =   l_transactions(i).CM_LINE_DESC,
                    memo_line_id    =   l_transactions(i).memo_line_id   
                where   
                    customer_trx_id =   x_credit_trx_id
                    and customer_trx_line_id =   l_transactions(i).cm_trx_line_id  ;
                    
                forall  i   in  1   ..  l_transactions.COUNT
                    update  
                        RA_CUST_TRX_LINE_GL_DIST_ALL
                    set code_combination_id =   l_transactions(i).cm_trx_line_ccid
                    where
                        customer_trx_line_id    =   l_transactions(i).cm_trx_line_id;   
                                                                                
            end loop;
            close   line_records;    
                                                        
            x_api_status    :=  v_return_status;
            x_message       :=  'ÝADE FATURA BAÞARIYLA OLUÞTURULDU';
            fnd_file.put_line(fnd_file.log,x_message);
            --commit;    --   commit  per transaction header
            
        end if;    
    exception   when    others  then
        XXMIP_GLOBAL_XLS_UTIL_PKG.set_header_process_status (p_header_id,fnd_global.CONC_REQUEST_ID,'Y'); --  set is_processed    executing
        x_api_status    :=  'E';
        x_message :=  sqlerrm;
    End credit_invoice;     
    
    function    check_credit_amount_per_line    
    (
        p_customer_Trx_line_id   in  number,
        p_trx_line_number   in  number                                
    )   return  number  is
    
    l_result    number;
    
    Begin                    
        
        select
            sum(extended_amount) into   l_result
        from
            apps.ra_customer_trx_lines_all
        where
            PREVIOUS_CUSTOMER_TRX_LINE_ID    =   p_customer_Trx_line_id
            --            and line_number =   p_trx_line_number
            and line_type   =   'LINE';    
        
        return  l_result;
    
    End check_credit_amount_per_line; 
    
    procedure   validate_lines  (
        x_status    out varchar2,
        x_error_msg out varchar2, 
        p_trx_number   in  varchar2,
        p_sob_id    in  number,
        p_header_id in  number   
    )   is
    
    cursor  line_records    is
    select
        TRX_LINE_NUM,
        CM_LINE_DESC,
        CM_LINE_ITEM,
        QUANTITY,
        UNIT_PRICE,
        TRX_NUMBER,
        SOB,
        to_number(null) as  customer_trx_line_id
    from
        XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
    where
        trx_number      =   p_trx_number
        and sob         =   p_sob_id   
        and header_id   =   p_header_id; 
    
    type    lines    is  table   of  line_records%ROWTYPE    INDEX BY PLS_INTEGER;    
    l_transactions  lines; 
    
    l_cust_trx_line_id  number;
    l_cust_trx_line_amt number;

    l_line_amt_check    varchar2(1);
    l_lines_check       varchar2(1);

    Begin
            
        x_status    :=  fnd_api.G_RET_STS_SUCCESS;
        
        open    line_records;
        loop
            
            fetch   line_records    bulk    collect into    l_transactions  limit   100;
            exit    when    l_transactions.COUNT    =   0;
            
            for sel in  1    ..  l_transactions.LAST loop
                                            
                Begin
                    select
                        customer_trx_line_id,extended_amount 
                            into    l_cust_trx_line_id,
                                    l_cust_trx_line_amt
                    from
                        ra_customer_trx_lines_all   rctl,
                        ra_customer_trx_all rct
                    where
                        rctl.customer_trx_id    =   rct.customer_trx_id
                        and rct.trx_number  =   l_transactions(sel).TRX_NUMBER
                        and rct.SET_OF_BOOKS_ID =   l_transactions(sel).SOB
                        and line_number =   l_transactions(sel).TRX_LINE_NUM
                        and rctl.line_type   =   'LINE';                    
                    exception   when    no_data_found   then
                        l_lines_check   :=  'E';
                        exit; 
                        when    too_many_rows   then
                        l_lines_check   :=  'E';
                        exit;           
                        when    others  then
                        l_lines_check   :=  'E';
                        exit;
                End;    

                
                if  (   l_cust_trx_line_id is  not null )   then
            
                    l_lines_check   :=  'S';
                                             
                    dbms_output.put_line('TOPLAM ÝADE : '||ABS(l_transactions(sel).QUANTITY *   l_transactions(sel).UNIT_PRICE));
                    dbms_output.put_line('TOPLAM UYGULANMIS: '||ABS(check_credit_amount_per_line(l_cust_trx_line_id,l_transactions(sel).TRX_LINE_NUM)));
                    dbms_output.put_line('TOPLAM KALEM: '||l_cust_trx_line_amt);          
                                                            
                                        
                    if  (   
                            (
                            round(ABS(l_transactions(sel).QUANTITY *   l_transactions(sel).UNIT_PRICE),2)    +   
                            ABS(check_credit_amount_per_line(l_cust_trx_line_id,l_transactions(sel).TRX_LINE_NUM))
                            )     
                            >   
                            l_cust_trx_line_amt     
                    )                           
                    then
                        dbms_output.put_line('HERE AMOUNT VALIDATE FAILED');
                        l_line_amt_check    :=  'E';
                        exit;
                    
                    else
                        dbms_output.put_line('HERE AMOUNT VALIDATE PASSED');
                        l_line_amt_check    :=  'S';                                            
                                           
                    end if; 
            
                else
            
                    l_lines_check   :=  'E';    
                    exit;
                end if;
                                
            end loop;                        
                
            if  (   l_lines_check    =   'E'    )    then        
                x_status            :=  fnd_api.g_ret_sts_error;
                x_error_msg         :=  'ÝÞLEM SERVÝS NO GEÇERSÝZ';            
                return;                
            end if;
        
            if  (   l_line_amt_check    =   'E' )   then        
                x_status            :=  fnd_api.g_ret_sts_error;    --  'E'
                x_error_msg         :=  'SATIR TUTARI ÝADE EDÝLEBÝLÝR TUTARDAN FAZLA';                
                return;        
            end if;                         
            
        end loop;
        close   line_records;
                   
        if  (   l_lines_check   =   'S' and l_line_amt_check    =   'S' )   then
                
            x_status    :=  fnd_api.G_RET_STS_SUCCESS;    --    'S'
            x_error_msg :=  null;
                
        end if;    
                                                                                                                                                  
    End validate_lines;                   
    
    procedure    get_item_memo (
        x_memo_line_id  out number,
        p_item_description  in  varchar2
    )   is
    
    Begin
    
        Begin
        
            select  
                memo_line_id    into    x_memo_line_id
            from    
                ar_memo_lines_all_tl    
            where   
                description     =   p_item_description
                and language    =   'TR';
        
        exception   when    others  then
            x_memo_line_id :=  -1;
        End;                

    End get_item_memo; 
    
    procedure   check_header  (
        x_status    out varchar2,
        x_error_msg out varchar2,
        p_paper_num in  varchar2,   --  iade    fatura  matbuu  no
        p_header_id in  number    
    )   is                
        
    cursor  paper_records    is
    select
        header_id,
        interface_line_id,
        trx_number,
        sob,
        cm_paper_number,
        cm_currency_rate,        
        currency_code,        
        api_msg,
        SUCCESS_FLAG,
        CM_TRX_ID,
        CUSTOMER_TRX_ID,
        IS_PROCESSED
    from
        XXMIP.XXMIP_CREDIT_MEMO_INTERFACE    
    where
        header_id           =   p_header_id
        and CM_PAPER_NUMBER =   p_paper_num
        and NVL(is_processed,'N')   =   'N' or (is_processed=  'Y' and NVL(success_flag,'E')    =   'E');        
    
    type    records_table   is  table   of  paper_records%ROWTYPE   index   by  pls_integer;
    --l_records   records_table;        
    
    l_paper_currency    varchar2(3);
    l_usd_currency_rate number;
    
    Begin
        
        x_status    :=  'S';
        x_error_msg :=  null;
    
        --  STEP    1   CHECK   MULTI   CURRENCY
        Begin
        
            select
               distinct currency_code    into    l_paper_currency    
            from
                XXMIP.XXMIP_CREDIT_MEMO_INTERFACE    
            where
                HEADER_ID           =   p_header_id
                and CM_PAPER_NUMBER =   p_paper_num;           
        
        exception   
            when    too_many_rows  then
                x_status    :=  'E';
                FND_MESSAGE.clear;                
                FND_MESSAGE.set_name('XXMIP', 'XXMIP_CM_MULTIPLE_CURRENCY');
                x_error_msg :=  FND_MESSAGE.get;
                return;
            when    no_data_found   then
                x_status    :=  'E';            
                x_error_msg :=  'Invalid Parameters';
                return;
        End;
        
        --  STEP    2   CHECK   UNIQUE  RATE    FOR USD CREDIT
        if  (   l_paper_currency   =   'USD'    )   then
        
            Begin
            
                select
                    distinct(CM_CURRENCY_RATE)    into    l_usd_currency_rate    
                from    
                    XXMIP.XXMIP_CREDIT_MEMO_INTERFACE    
                where
                    HEADER_ID           =   p_header_id
                    and CM_PAPER_NUMBER =   p_paper_num;
            
            exception   when    too_many_rows   then
                x_status    :=  'E';
                FND_MESSAGE.clear;                
                FND_MESSAGE.set_name('XXMIP', 'XXMIP_CM_USD_RATE_CONTROL');
                x_error_msg :=  FND_MESSAGE.get;
                return;                
            End;
        
        end if;                                                        
    
    End check_header; 
    
    function    get_total_applied_receipt   (
        p_customer_trx_id   in  number   
    )   return  number  is
    
    l_pay_check number;
    
    Begin
        
        SELECT  
            NVL(SUM(ARA.amount_applied),0)   into    l_pay_check     
        FROM 
            apps.AR_RECEIVABLE_APPLICATIONS_ALL ARA, 
            apps.AR_CASH_RECEIPTS_ALL ACR, 
            apps.RA_CUSTOMER_TRX_ALL RCT 
        WHERE 
            ARA.STATUS  ='APP' 
            AND ARA.CASH_RECEIPT_ID=ACR.CASH_RECEIPT_ID 
            AND ARA.APPLIED_CUSTOMER_TRX_ID=RCT.CUSTOMER_TRX_ID
            AND RCT.customer_trx_id =   p_customer_trx_id;    
    
        return  l_pay_check;  

    End get_total_applied_receipt; 
    
    procedure   check_transaction   (
        x_status        out varchar2,
        x_error_msg     out varchar2,
        p_header_id in  number,
        p_trx_number    in  varchar2,
        p_sob_id    in  number 
    )   is
                
    l_customer_trx_id   number;
    l_inv_currency_code varchar2(15);
    l_inv_exchange_rate number;
    
    l_period_name   varchar2(15);
    
    --  credit  memo    header  vals
    l_cm_trx_date   date;            
    l_cm_note   varchar2(4000); 
    l_cm_paper_number   varchar2(500);
    l_cm_currency_rate  number;
    l_cm_currency_rate_date date;
    l_cm_currency_code  varchar2(15);
    
    --  line    values
    l_cust_trx_line_id  number;
    l_cust_trx_line_amt number;
    l_cust_trx_line_desc    AR.RA_CUSTOMER_TRX_LINES_ALL.DESCRIPTION%TYPE;
    l_lines_check   varchar2(1);
    l_line_amt_check    varchar2(1);
    l_line_memo_line_check  varchar2(1);
    l_line_desc_check   varchar2(1);
    l_total_cm_applied  number;
    l_memo_line_id  number;
    
    
    l_ar_period_status  varchar2(5);
    cursor  transaction_lines   is
    select
        trx_line_num,
        quantity,
        unit_price,
        cm_line_desc,
        TRX_LINE_DESC   
    from
        XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
    where
        header_id   =   p_header_id
        and trx_number  =   p_trx_number
        and sob =   p_sob_id;
            
    Begin
            
        x_status    :=  'S';                                                    
        --  step    1   check   the trx number        
        Begin
            
            select
                customer_trx_id,    
                invoice_currency_code,
                case    invoice_currency_code
                    when    'TRY'   then    to_number(replace(attribute4,',','.'))
                    else    exchange_rate
                end 
            into    
                l_customer_trx_id,
                l_inv_currency_code,
                l_inv_exchange_rate
            from
                AR.RA_CUSTOMER_TRX_ALL  rct
            where
                RCT.TRX_NUMBER  =   p_trx_number
                and rct.set_of_books_id =   p_sob_id
                and cust_trx_type_id    =   CASE    p_sob_id
                                                WHEN    1001    then    1000
                                                WHEN    1003    then    1027
                                            END;--  invoice,marine invoice;    --  invoice            
        exception   
            when    no_data_found   then
                x_status    :=  'E';
                x_error_msg :=  'ISLEM NUMARASINA AIT FATURA ISLEMI BULUNAMADI';   
                return;
            when    too_many_rows   then
                x_status    :=  'E';
                x_error_msg :=  'AYNI ISLEM NUMARASINA SAHIP BIRDEN FAZLA KAYIT VAR';   
                return;                
        End;    
        
        --  data    integrity
        Begin
            select
                distinct    
                    trunc(cm_trx_date),
                    cm_note,
                    cm_paper_number,
                    cm_currency_rate,
                    NVL(trunc(CM_RATE_DATE),trunc(cm_trx_date)),
                    currency_code
                into
                    l_cm_trx_date,
                    l_cm_note,
                    l_cm_paper_number,
                    l_cm_currency_rate,
                    l_cm_currency_rate_date,
                    l_cm_currency_code        
            from
                XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
            where
                trx_number      =   p_trx_number
                and sob         =   p_sob_id
                and header_id   =   p_header_id;
        
        exception   when    too_many_rows   then
                x_status    :=  'E';
                x_error_msg :=  'AYNI ÝÞLEM NO ÝÇÝN FARKLI DEÐER MEVCUT(NOT,KUR,MATBUU NO,TARÝH)';                
                return;    
        end;
                
        --  step    2   check   currency    code
        Begin                        
            if  (   l_inv_currency_code    <>  l_cm_currency_code  )    then        
                dbms_output.put_line('l_inv_currency_code: '||l_inv_currency_code||' l_cm_currency_code: '||l_cm_currency_code);        
                x_status    :=  'E';
                FND_MESSAGE.clear;                
                FND_MESSAGE.set_name('XXMIP', 'XXMIP_CM_CURRENCY_MISMATCH');
                x_error_msg :=  FND_MESSAGE.get;
                return;             
            end if;                            
        End;
        
        --  step    3   check   currency    rate    for TRY credit  memo 
        Begin            
            if  (   l_cm_currency_code   =   'TRY'   )   then            
                if  (   l_inv_exchange_rate  <>  l_cm_currency_rate )   then    
                    dbms_output.put_line('l_inv_exchange_rate: '||l_inv_exchange_rate||' l_cm_currency_rate: '||l_cm_currency_rate);
                    x_status    :=  'E';
                    FND_MESSAGE.clear;                
                    FND_MESSAGE.set_name('XXMIP', 'XXMIP_CM_TRY_RATE_CONTROL');
                    x_error_msg :=  FND_MESSAGE.get;
                    return;                                         
                end if;                    
            end if;            
        End;
        
        --  step    4   check   applied receipts    on  invoice        
        if  (   get_total_applied_receipt(l_customer_trx_id)   >   0    )    then
        
            x_status    :=  'E';
            FND_MESSAGE.clear;                
            FND_MESSAGE.set_name('XXMIP', 'XXMIP_CM_RECEIPT_CONTROL');
            x_error_msg :=  FND_MESSAGE.get;
            return;    
        
        end if;
        
        --  step    5   check   cm  date
        Begin            
            select
                PERIOD_NAME into    l_period_name
            from
                apps.gl_periods
            where
                PERIOD_SET_NAME =   'MIP TAKVIM'
                and l_cm_trx_date   between start_date  and end_date;
            
            exception   when    no_data_found   then
                x_status    :=  'E';
                x_error_msg       :=  'GÝRÝLEN TARÝH TAKVÝMDE BULUNAMADI';                
                return;         
        End;
        
        Begin            
            select
                closing_status  into    l_ar_period_status
            from
            gl_period_statuses
            where   
            application_id = 222
            and l_cm_trx_date   between start_date  and end_date
            and set_of_books_id = p_sob_id;
            
            exception   when    no_data_found   then
                x_status    :=  'E';
                x_error_msg       :=  'GÝRÝLEN TARÝH TAKVÝMDE BULUNAMADI';                
                return;         
        End;
        
        if  ( l_ar_period_status <>  'O')    then
            
            x_status    :=  'E';
            x_error_msg       :=  'GÝRÝLEN AR PERÝOD ACIK DEGÝL';                
            return;
        
        end if;
        
        --  step 6 for  each transaction check  line    numbers,amount  comparison
        for sel in  transaction_lines   loop
            
            l_memo_line_id  :=  -1;
            l_lines_check   :=  'S';
        
            Begin                
                select
                    rctl.customer_trx_line_id,
                    rctl.extended_amount,
                    NVL(sum(rctl2.extended_amount) ,0),
                    memo_lines_tl.NAME
                into    
                    l_cust_trx_line_id,
                    l_cust_trx_line_amt,
                    l_total_cm_applied,
                    l_cust_trx_line_desc
                from
                    ra_customer_trx_lines_all   rctl,
                    ra_customer_trx_lines_all   rctl2,
                    apps.ar_memo_lines_tl   memo_lines_tl
                where
                    rctl.customer_trx_id    =   l_customer_trx_id
                    and rctl.line_number    =   sel.trx_line_num 
                    and rctl.line_type      =   'LINE'
                    and rctl.memo_line_id = memo_lines_tl.memo_line_id(+)
                    and NVL(memo_lines_tl.language,'TR')  =   'TR'                    
                    and rctl.customer_trx_line_id   =   rctl2.previous_customer_trx_line_id (+)
                    and NVL(rctl2.line_type,'LINE') =   'LINE'
                group   by  
                    rctl.customer_trx_line_id,
                    rctl.extended_amount,
                    rctl.line_number,
                    memo_lines_tl.NAME; 
            exception   
                when    no_data_found   then
                    l_lines_check   :=  'E';
                    exit; 
                when    too_many_rows   then
                    l_lines_check   :=  'E';
                    exit;           
                when    others  then
                    l_lines_check   :=  'E';
                    exit;
            End;
            
            if  (   (   round(ABS(sel.quantity *   sel.UNIT_PRICE),2)    +   ABS(l_total_cm_applied)) > l_cust_trx_line_amt )    then
                l_line_amt_check    :=  'E';
                exit;                    
            else                        
                l_line_amt_check    :=  'S';                                                                                       
            end if; 
            
            xxmip_ar_mass_cm_pkg.get_item_memo   (
                x_memo_line_id      =>  l_memo_line_id,
                p_item_description  =>  sel.cm_line_desc    --  TR  Item    Description
            )   ;
            
            if  (   l_memo_line_id  =   -1  ) then
                l_line_memo_line_check  :=  'E';
                exit;
            end if;                                                                        
            
            if( sel.TRX_LINE_DESC   <>  l_cust_trx_line_desc)   then                
                l_line_desc_check   :=  'E';
                exit;
            end if;
            
        end loop;
        
        if  (   l_lines_check    =   'E'    )    then        
            x_status            :=  'E';
            x_error_msg         :=  'ORJÝNAL SERVÝS NO GEÇERSÝZ '||p_trx_number;            
            return;                
        end if;
        
        if  (   l_line_amt_check    =   'E' )   then        
            x_status            :=  'E';    --  'E'
            x_error_msg         :=  'ÝADE TUTARI ÝADE EDÝLEBÝLÝR TUTARDAN FAZLA '||p_trx_number;                
            return;        
        end if;
        
        if  (   l_line_memo_line_check    =   'E' )   then        
            x_status            :=  'E';    --  'E'
            x_error_msg         :=  'ÝADE FATURA NOT SATIRI AÇIKLAMASINA AIT KALEM BULUNAMADI '||p_trx_number;                
            return;        
        end if;
        
        if  (   l_line_desc_check   =   'E' )   then
            x_status            :=  'E';    --  'E'
            x_error_msg         :=  'BELÝRTTÝÐÝNÝZ SATIR KALEM NUMARASI ÝÇÝN KALEM ADI UYUÞMAZLIÐI VAR '||p_trx_number;                
            return;        
        end if;
                
    End check_transaction ;
    
    procedure   check_file  (
        errbuff    out varchar2,
        retcode out varchar2,
        p_header_id in  number,
        p_responsibility_id in  number,
        p_function_param    in  varchar2            
    )   is
    
    l_param_status  varchar2(50);
    l_param_msg     varchar2(150);
        
    l_number_of_paper_num   number  :=  0;
    l_number_of_error_paper_num   number    :=  0;
    
    l_num_of_trx_per_paper number :=  0;
    l_num_of_error_trx_per_paper number   :=  0;
    
    cursor  headers   is
    select
        CM_PAPER_NUMBER,
        to_char(null)   as  PAPER_STATUS,
        to_char(null)   as  PAPER_ERROR_MSG 
    from
        XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
    where
        header_id   =   p_header_id
    group   by  CM_PAPER_NUMBER;
    
    cursor  transactions    (   p_paper_number in  varchar2 )    is
    select
        HEADER_ID,
        interface_line_id,
        TRX_NUMBER,
        SOB,
        to_char(null)   as  transaction_status,
        to_char(null)   as  transaction_error_msg 
    from
        XXMIP.XXMIP_CREDIT_MEMO_INTERFACE
    where
        header_id   =   p_header_id
        and cm_paper_number =   p_paper_number;           
    
    Begin
            
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,''';
    
        retcode :=   '0'; --  SUCCESS
    
        fnd_file.put_line(fnd_file.output,'*****************');
        fnd_file.put_line(fnd_file.output,'-----PARAMETERS-----');
        fnd_file.put_line(fnd_file.output,'DOSYA NO:   '||p_header_id);
        fnd_file.put_line(fnd_file.output,'RESP_ID:    '||p_responsibility_id);
        fnd_file.put_line(fnd_file.output,'DOSYA TIPI: '||p_function_param);
        fnd_file.put_line(fnd_file.output,'*****************');
        
        XXMIP_GLOBAL_XLS_UTIL_PKG.validate_parameters (
            X_STATUS    =>  l_param_status,
            X_ERROR_MSG =>  l_param_msg,
            P_HEADER_ID =>  p_header_id,
            P_RESPONSIBILITY_ID =>  p_responsibility_id,
            P_FUNCTION_PARAM    =>  p_function_param        
        );
        
        if  (   l_param_status   =   'ERROR'    )   then
            
            retcode :=  '2';  
            errbuff :=  l_param_msg;    
            
        else    
            
            l_number_of_paper_num       :=  0;
            l_number_of_error_paper_num :=  0;
        
            for sel in  headers loop  
                
                fnd_file.put_line(fnd_file.output,'---------------');
                fnd_file.put_line(fnd_file.output,' MATBUU NO: '||sel.CM_PAPER_NUMBER);
                
                l_number_of_paper_num   :=  l_number_of_paper_num   +   1;
                
                XXMIP_AR_MASS_CM_PKG.CHECK_HEADER   (
                                            X_STATUS    =>  sel.PAPER_STATUS,
                                            X_ERROR_MSG =>  sel.PAPER_ERROR_MSG,
                                            p_paper_num =>  sel.CM_PAPER_NUMBER,
                                            P_HEADER_ID =>  p_header_id  
                );                
                     
                if  (   sel.PAPER_STATUS   =   'E'  )   then
                    
                    l_number_of_error_paper_num :=  l_number_of_error_paper_num +   1;                                                        
                    fnd_file.put_line(fnd_file.output,' STATUS: '||sel.PAPER_STATUS);
                    fnd_file.put_line(fnd_file.output,' ERROR_MSG: '||sel.PAPER_ERROR_MSG);                                        
                    
                else                                                        
                    
                    l_num_of_trx_per_paper  :=  0;
                    l_num_of_error_trx_per_paper    :=  0;
                    
                    for indx   in  transactions(sel.CM_PAPER_NUMBER)   loop                        
                        
                        l_num_of_trx_per_paper  :=  l_num_of_trx_per_paper  +   1;
                    
                        XXMIP_AR_MASS_CM_PKG.CHECK_TRANSACTION  (
                                                X_STATUS        =>  indx.transaction_status,
                                                X_ERROR_MSG     =>  indx.transaction_error_msg,
                                                P_HEADER_ID     =>  indx.HEADER_ID,
                                                P_TRX_NUMBER    =>  indx.TRX_NUMBER,
                                                P_SOB_ID        =>  indx.SOB
                        );                                                
                        
                                                
                        if  (   indx.transaction_status  =   'E'    )    then
                            fnd_file.put_line(fnd_file.log,' ERROR MSG: '||indx.transaction_error_msg);
                            l_num_of_error_trx_per_paper    :=  l_num_of_error_trx_per_paper    +   1;                            
                        end if;                        
                    
                    end loop;
                    
                    if  (   l_num_of_error_trx_per_paper    >   0   )    then
                    
                        l_number_of_error_paper_num :=  l_number_of_error_paper_num +   1;
                    
                    end if; 
                   
                    fnd_file.put_line(fnd_file.output,'  TOPLAM FATURA SAYISI: '||l_num_of_trx_per_paper);    --  l_num_of_error_trx_per_paper
                    fnd_file.put_line(fnd_file.output,'  HATALI FATURA SAYISI: '||l_num_of_error_trx_per_paper);
                                                            
                end if;                                           
                
            end loop;
                        
        end if;
        
            fnd_file.put_line(fnd_file.output,'***KONTROL ÝÞLEM SONUÇLARI***');
            fnd_file.put_line(fnd_file.output,'Toplam Matbuu No Sayýsý: '||l_number_of_paper_num);     
            fnd_file.put_line(fnd_file.output,'Toplam Hatalý Matbuu No Sayýsý: '||l_number_of_error_paper_num);         
            fnd_file.put_line(fnd_file.output,'***KONTROL ÝÞLEM SONUÇLARI***');
            
            if  (   l_number_of_error_paper_num    >   0    )  then
            
                retcode :=   '1'; --  WARNING
                errbuff :=  'HATALI MATBUU NOLAR MEVCUT';
            
            end if;
    
    exception   when    others  then
        retcode :=  '2';  --  ERROR
        errbuff :=  sqlerrm;
        
    End check_file;       
    
END XXMIP_AR_MASS_CM_PKG;
/