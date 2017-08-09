CREATE OR REPLACE PACKAGE BODY APPS.XXMIP_AR_MASS_TRANS_CANCEL_PKG  as
    
    /*
    procedure   create_single_invoice   (    
        x_customer_trx_id   out number,
        p_user_id   in  number,
        p_resp_id   in  number,
        p_org_id    in  number  default 101,
        p_transaction_id    in  number
    )   is
    
    cursor  invoice_header  is  
        select            
            trx_number,
            trx_date,
            set_of_books_id,
            sysdate as  creation_date,
            sysdate as  last_update_date,
            batch_source_id,
            batch_id,
            null as sold_to_customer_id,
            bill_to_customer_id,
            bill_to_site_use_id,
            null    as  remit_to_Address_id,
            null    as  term_id,
            to_date(null)   as  term_due_date,
            customer_trx_id as  PREVIOUS_CUSTOMER_TRX_ID,
            printing_option,
            printing_pending,
            sysdate as  CUSTOMER_REFERENCE_DATE,
            invoice_currency_code,
            status_trx,
            ATTRIBUTE_CATEGORY,
            attribute1,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            attribute6,
            attribute7,
            attribute8,
            attribute9,
            attribute10,
            program_application_id,
            program_id,
            sysdate as  program_update_date,
            complete_flag,
            attribute11,    --  iptal   notu    custom  tablodan    gelecek
            attribute12,
            attribute13,
            attribute14,
            attribute15,
            INTERFACE_HEADER_ATTRIBUTE1,
            CT_REFERENCE,
            1004    as  CUST_TRX_TYPE_ID,
            'ARXTWCMI'  as  created_from,
            org_id,
            101 as  legal_entity_id
        from
            ra_customer_trx_all ra  --  custom_tablo_ile_birleþtirilecek
        where
            trx_number  =   '385690'
            and set_of_books_id =   1001
            and not exists  (   --  eþleþtirme yapýlmamýþ olma  kontrolü
                SELECT  
                    ACR.RECEIPT_NUMBER RECEIPT_NO 
                FROM 
                    AR_RECEIVABLE_APPLICATIONS_ALL ARA, 
                    AR_CASH_RECEIPTS_ALL ACR, 
                    RA_CUSTOMER_TRX_ALL RCT 
                WHERE 
                    ARA.STATUS  ='APP' 
                    AND ARA.CASH_RECEIPT_ID=ACR.CASH_RECEIPT_ID 
                    AND ARA.APPLIED_CUSTOMER_TRX_ID=RCT.CUSTOMER_TRX_ID
                    AND RCT.customer_trx_id =   ra.customer_trx_id                
            );
    
    cursor  header_lines    (p_customer_Trx_id  in  number)    is  
        select
            *
        from
            ra_customer_trx_lines_all
        where
            customer_trx_id =   p_customer_Trx_id
        order   by  line_type   asc;    --  LINE,TAX   

    l_cust_header_id        number;
    l_cust_line_id          number;
                  
    l_return_status         VARCHAR2 (1);
    l_msg_count             NUMBER;
    l_msg_data              VARCHAR2 (2000);
    l_batch_id              NUMBER;
    l_batch_source_rec      ar_invoice_api_pub.batch_source_rec_type;
    l_trx_header_tbl        ar_invoice_api_pub.trx_header_tbl_type;
    l_trx_lines_tbl         ar_invoice_api_pub.trx_line_tbl_type;
    l_trx_dist_tbl          ar_invoice_api_pub.trx_dist_tbl_type;
    l_trx_salescredits_tbl  ar_invoice_api_pub.trx_salescredits_tbl_type;
    l_trx_contingencies_tbl ar_invoice_api_pub.trx_contingencies_tbl_type;
    trx_header_id_v         NUMBER;
    trx_line_id_v           NUMBER;
    trx_dist_id_v           NUMBER;
    header_counter          NUMBER;
    line_counter            NUMBER;
    
    Begin
        
        Begin
        
            fnd_global.apps_initialize (p_user_id, p_resp_id, p_org_id);
            mo_global.init ('AR');
            mo_global.set_policy_context ('S', p_org_id);
            xla_security_pkg.set_security_context (p_org_id);
        
        End;               
        
        for sel in  invoice_header  loop
            
            l_batch_source_rec.batch_source_id  :=   sel.batch_source_id;
        
            select
                XXMIP_AR_INV_HDR_SEQ.nextval    into    l_cust_header_id
            from
                dual; 
        
            header_counter  :=  1;
            
            l_trx_header_tbl(header_counter).trx_header_id          :=  l_cust_header_id; 
            l_trx_header_tbl(header_counter).trx_date               :=  sel.trx_date;
            l_trx_header_tbl(header_counter).trx_currency           :=  sel.invoice_currency_code;
            l_trx_header_tbl(header_counter).reference_number       :=  sel.CT_REFERENCE;
            l_trx_header_tbl(header_counter).trx_class              :=  'CM';   --  Credit  Memo
            l_trx_header_tbl(header_counter).cust_trx_type_id       :=  sel.CUST_TRX_TYPE_ID;                
            l_trx_header_tbl(header_counter).gl_date                :=  sel.trx_date;
            l_trx_header_tbl(header_counter).bill_to_customer_id    :=  sel.bill_to_customer_id;
            l_trx_header_tbl(header_counter).bill_to_account_number :=  null;
            l_trx_header_tbl(header_counter).bill_to_customer_name  :=  null;
            l_trx_header_tbl(header_counter).bill_to_contact_id     :=  null;
            l_trx_header_tbl(header_counter).bill_to_address_id     :=  null;                                      
            l_trx_header_tbl(header_counter).bill_to_site_use_id    :=  sel.bill_to_site_use_id;
            l_trx_header_tbl(header_counter).ship_to_customer_id     :=  null; 
            l_trx_header_tbl(header_counter).ship_to_account_number     :=  null; 
            l_trx_header_tbl(header_counter).ship_to_customer_name     :=  null; 
            l_trx_header_tbl(header_counter).ship_to_contact_id     :=  null;
            l_trx_header_tbl(header_counter).ship_to_address_id     :=  null; 
            l_trx_header_tbl(header_counter).ship_to_site_use_id     :=  null;
            l_trx_header_tbl(header_counter).sold_to_customer_id     :=  sel.sold_to_customer_id;
            l_trx_header_tbl(header_counter).term_id     :=  null;
            l_trx_header_tbl(header_counter).primary_salesrep_id    :=  null;
            l_trx_header_tbl(header_counter).primary_salesrep_name  :=  null;
            l_trx_header_tbl(header_counter).exchange_rate_type     :=  null;
            l_trx_header_tbl(header_counter).exchange_date          :=  null;
            l_trx_header_tbl(header_counter).exchange_rate          :=  null;
            l_trx_header_tbl(header_counter).exchange_rate          :=  null;
            l_trx_header_tbl(header_counter).territory_id           :=  null;
            l_trx_header_tbl(header_counter).remit_to_address_id    :=  null;
            l_trx_header_tbl(header_counter).invoicing_rule_id      :=  null;
            l_trx_header_tbl(header_counter).printing_option        :=  sel.printing_option;
            l_trx_header_tbl(header_counter).purchase_order         :=  null;
            l_trx_header_tbl(header_counter).purchase_order_revision    :=  null;
            l_trx_header_tbl(header_counter).purchase_order_date        :=  null;
            l_trx_header_tbl(header_counter).comments               :=  null;
            l_trx_header_tbl(header_counter).internal_notes         :=  null;
            l_trx_header_tbl(header_counter).finance_charges        :=  null;
            l_trx_header_tbl(header_counter).receipt_method_id      :=  null;
            l_trx_header_tbl(header_counter).related_customer_trx_id    :=  null;
            l_trx_header_tbl(header_counter).agreement_id           :=  null;
            l_trx_header_tbl(header_counter).ship_via               :=  null;
            l_trx_header_tbl(header_counter).ship_date_actual       :=  null;
            l_trx_header_tbl(header_counter).waybill_number         :=  null;
            l_trx_header_tbl(header_counter).fob_point              :=  null;
            l_trx_header_tbl(header_counter).customer_bank_account_id     :=  null;
            l_trx_header_tbl(header_counter).default_ussgl_transaction_code     :=  null;
            l_trx_header_tbl(header_counter).status_trx     :=  sel.status_trx;
            l_trx_header_tbl(header_counter).paying_customer_id     :=  null;
            l_trx_header_tbl(header_counter).paying_site_use_id     :=  null;
            l_trx_header_tbl(header_counter).attribute_category     :=  sel.attribute_category;
            l_trx_header_tbl(header_counter).attribute1     :=  sel.attribute1;
            l_trx_header_tbl(header_counter).attribute2     :=  sel.attribute2;
            l_trx_header_tbl(header_counter).attribute3     :=  sel.attribute3;
            l_trx_header_tbl(header_counter).attribute4     :=  sel.attribute4;
            l_trx_header_tbl(header_counter).attribute5     :=  sel.attribute5;
            l_trx_header_tbl(header_counter).attribute6     :=  sel.attribute6;
            l_trx_header_tbl(header_counter).attribute7     :=  sel.attribute7;
            l_trx_header_tbl(header_counter).attribute8     :=  sel.attribute8;
            l_trx_header_tbl(header_counter).attribute9     :=  sel.attribute9;
            l_trx_header_tbl(header_counter).attribute10    :=  sel.attribute10;
            l_trx_header_tbl(header_counter).attribute11    :=  sel.attribute11;
            l_trx_header_tbl(header_counter).attribute12    :=  sel.attribute12;
            l_trx_header_tbl(header_counter).attribute13    :=  sel.attribute13;
            l_trx_header_tbl(header_counter).attribute14    :=  sel.attribute14;
            l_trx_header_tbl(header_counter).attribute15    :=  sel.attribute15;
            l_trx_header_tbl(header_counter).interface_header_attribute1    :=  sel.interface_header_attribute1;
            l_trx_header_tbl(header_counter).org_id :=   sel.org_id;
            l_trx_header_tbl(header_counter).legal_entity_id :=   sel.legal_entity_id;
            
            for x   in  header_lines    (sel.PREVIOUS_CUSTOMER_TRX_ID)   loop  
                
                select
                    XXMIP_AR_INV_LINE_SEQ.nextval    into    l_cust_line_id
                from
                    dual;    
                
                line_counter    :=  1;
                
                l_trx_lines_tbl(line_counter).trx_header_id :=  l_cust_header_id;
                l_trx_lines_tbl(line_counter).trx_line_id   :=  l_cust_line_id; 
                l_trx_lines_tbl(line_counter).line_number   :=  line_counter;                    
                
                line_counter    :=  line_counter    +   1;

            
            end loop;
            
            header_counter  :=  header_counter  +   1;

        end loop;  
    
    End create_single_invoice; 
    */
    procedure   credit_invoice  (
            x_api_status        out varchar2,
            x_message           out varchar2,
            x_credit_trx_id     out number,
            p_customer_trx_id   in  number,
            p_cancellation_note in  varchar2
            --p_user_id           in  number,
            --p_resp_id           in  number,
            --p_resp_appl_id      in  number                        
    )   is
    
    type invoicelines_records is table of ra_customer_trx_lines_all%rowtype index by pls_integer;
    l_cm_lines_tbl              arw_cmreq_cover.cm_line_tbl_type_cover;
    
    l_attribute_rec             arw_cmreq_cover.pq_attribute_rec_type;
    l_interface_attribute_rec   arw_cmreq_cover.pq_interface_rec_type;   
    
    l_invlines_recs     invoicelines_records;
    v_return_status     varchar2 (1);
    v_msg_count         number;
    v_msg_data          varchar2 (2400);
    v_request_id        number;
    p_count             number                                 := 0;
    l_orj_trx_date      date;
    l_line_tax_amount   number;
    l_cm_trx_id         number;    
    l_batch_source_name varchar2(50);
    l_org_id    number;
    
    l_computed_tax_amt  number  :=  0;
    
    Begin
    
        --fnd_global.apps_initialize (p_user_id, p_resp_id, p_resp_appl_id);                
 
        Begin
            select  
                trx_date,
                bs.name,
                ra.org_id
            into    
                l_orj_trx_date,
                l_batch_source_name,
                l_org_id
            from 
                ra_customer_trx_all     ra,
                ra_batch_sources_all    bs
            where   
                customer_trx_id = p_customer_trx_id
                and ra.batch_source_id  =   bs.batch_source_id
                and ra.org_id   =   bs.org_id;
        exception   when    others  then
            x_api_status    :=  fnd_api.g_ret_sts_error;
            x_message       :=  'Error Getting Batch Source Name'; 
            return;               
        End;
        
        Begin
            
            --            DBMS_APPLICATION_INFO.set_client_info(l_org_id);
            MO_GLOBAL.SET_POLICY_CONTEXT('S', l_org_id);
        
        End;
        
        select
            attribute_category,
            attribute1,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            attribute6,
            attribute7,
            attribute8,
            attribute9,
            attribute10,
            p_cancellation_note,
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
            customer_trx_id =   p_customer_trx_id;
                    
        begin
            select  *   bulk collect into l_invlines_recs
            from    
                ra_customer_trx_lines_all rctl
            where
                rctl.customer_trx_id = p_customer_trx_id
                and line_type = 'LINE';
        end ;
        
        if  l_invlines_recs.count = 0    then
            x_api_status    :=  fnd_api.g_ret_sts_error;
            x_message       :=  'KALEM TÝPÝNDE SATIR BULUNAMADI';            
            return;
        end if;
        
        for i in 1 .. l_invlines_recs.count loop
            --***********************************************************************************
            l_cm_lines_tbl (i).customer_trx_line_id :=  l_invlines_recs (i).customer_trx_line_id;
            l_cm_lines_tbl (i).quantity_credited    :=  l_invlines_recs (i).quantity_invoiced   *   -1;
            l_cm_lines_tbl (i).price                :=  l_invlines_recs (i).unit_selling_price  ;
            
            --***********************************************************************************
            l_computed_tax_amt                       :=  l_computed_tax_amt +   calc_line_tax_amount (l_invlines_recs (i).customer_trx_line_id);
            --***********************************************************************************
            l_cm_lines_tbl (i).extended_amount      :=  round((l_invlines_recs (i).quantity_invoiced   * l_invlines_recs (i).unit_selling_price    * -1),2);
        end loop;                      
        
        fnd_msg_pub.initialize;
        ar_credit_memo_api_pub.create_request
                                            (   
                                                p_api_version                   =>  1.0
                                                ,p_init_msg_list                =>  fnd_api.g_true
                                                ,p_commit                       =>  fnd_api.g_false
                                                ,p_customer_trx_id              =>  p_customer_trx_id
                                                ,p_line_credit_flag             =>  'Y'
                                                ,p_cm_line_tbl                  =>  l_cm_lines_tbl
                                                ,p_cm_reason_code               =>  'CANCELLATION'  --  iptal   fatura
                                                ,p_skip_workflow_flag           =>  'Y'
                                                ,p_batch_source_name            =>  l_batch_source_name 
--                                                ,p_tax_amount                   =>  l_computed_tax_amt                                               
                                                ,p_credit_method_installments   =>  null
                                                ,p_credit_method_rules          =>  null
                                                ,x_return_status                =>  v_return_status
                                                ,x_msg_count                    =>  v_msg_count
                                                ,x_msg_data                     =>  v_msg_data
                                                ,x_request_id                   =>  v_request_id
                                                ,p_attribute_rec                =>  l_attribute_rec
                                                --,p_interface_attribute_rec      =>  l_interface_attribute_rec
                                                ,p_gl_date                      =>  l_orj_trx_date                                                      
                                            );
        
        log_step    (
                        p_package_name      =>  'XXMIP_AR_MASS_TRANS_CANCEL_PKG', 
                        p_procedure_name    =>  'CREDIT_INVOICE',
                        p_message           =>  'AFTER API PARAMS Message '||v_msg_data,               
                        p_api_status        =>  v_return_status                   
        );

        if  v_return_status <> fnd_api.g_ret_sts_success    then
            
            if  v_msg_count = 1  then                
            
                x_api_status    :=  fnd_api.g_ret_sts_error;
                x_message       :=  v_msg_data;                
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
        
        else                        
        
            x_credit_trx_id := get_memo_trx_id (v_request_id);            
            
            log_step    (
                        p_package_name      =>  'XXMIP_AR_MASS_TRANS_CANCEL_PKG', 
                        p_procedure_name    =>  'CREDIT_INVOICE',
                        p_message           =>  'AFTER API PARAMS SUCCESS '||x_credit_trx_id,               
                        p_api_status        =>  v_return_status                   
            );
                  
            
            if l_cm_trx_id = 0  then
                x_api_status        :=  fnd_api.g_ret_sts_error;
                x_message           :=  'Request_id : '|| v_request_id|| ' '|| ' , No cm_trx_id found RA_CM_REQUESTS_ALL';
                return;
            end if;
            
            update  
                ra_customer_trx_all 
            set 
                cust_trx_type_id    =   1004,
                trx_date   =   l_orj_trx_date       
            where   
                customer_trx_id =   x_credit_trx_id;
                
            update  
                ra_customer_trx_all 
            set 
                attribute11    =   p_cancellation_note    
            where   
                customer_trx_id =   p_customer_trx_id;    
                        
                
            update_tax_lines_ccid   (
                                    p_customer_trx_id,
                                    x_credit_trx_id
            );        
                
            x_api_status    :=  v_return_status;
            x_message       :=  'ÝPTAL FATURA BAÞARIYLA OLUÞTURULDU';
            
        end if;

        commit;

    End credit_invoice;

    function calc_line_tax_amount (p_customer_trx_line_id in number)    return number   is
    
    l_tax_amount   number;
    
    begin
        
        select 
            sum (nvl (extended_amount, 0))  into l_tax_amount
        from 
            ra_customer_trx_lines_all rctl
        where 
            line_type = 'TAX'
            and rctl.link_to_cust_trx_line_id = p_customer_trx_line_id;

        return l_tax_amount;
        
    end calc_line_tax_amount; 
    
    function get_memo_trx_id (   p_req_id in number  )  return number   is
        
        l_cm_trx_id   ra_cm_requests_all.cm_customer_trx_id%type;
        
    begin
        select cm_customer_trx_id
            into l_cm_trx_id
        from 
            ra_cm_requests_all
        where 
            cm_customer_trx_id is not null
            and request_id = p_req_id;

        return l_cm_trx_id;
    exception
        when others then
        return 0;
    end get_memo_trx_id;
    
    procedure   start_File_Transaction  (   
                                        x_request_id    out varchar2,
                                        p_file_id  in  varchar2,
                                        p_user_id   in  number,
                                        p_resp_id   in  number,
                                        p_resp_appl_id  in  number
    )   is
        
    
    Begin
        
        fnd_global.apps_initialize (p_user_id, p_resp_id, p_resp_appl_id);
        
        x_request_id    :=  fnd_request.submit_request ( 
                            application   => 'XXMIP', 
                            program       => 'XXMIP_AR_BATCH_CANCEL_PROGRAM', 
                            description   => null, 
                            start_time    => sysdate, 
                            sub_request   => false,
                            argument1     => p_file_id
        );
        
        COMMIT;
        
        IF  x_request_id = 0
        THEN
            dbms_output.put_line ('Concurrent request failed to submit');
        ELSE
            dbms_output.put_line('Successfully Submitted the Concurrent Request');
            dbms_output.put_line('Request_Id: '||x_request_id);
        END IF;
    exception   when    others  then
            dbms_output.put_line(sqlerrm);
        /*open    transactions;
        loop
            fetch   transactions    bulk    collect into    l_transactions  limit   250;               
            exit    when    l_transactions.COUNT    =   0;    
            
            for i   in  1   ..  l_transactions.COUNT    loop                
                Begin
                    select  customer_trx_id into
                        l_transactions(i).customer_trx_id
                    from    
                        ra_customer_trx_all 
                    where   
                        trx_number  =   l_transactions(i).TRX_NUMBER  
                        and set_of_books_id =   l_transactions(i).SET_OF_BOOKS_ID;
                exception   
                    when    too_many_rows   then
                            l_transactions(i).IS_PROCESSED      :=  'N';
                            l_transactions(i).IS_CANCELLED      :=  'E';
                            l_transactions(i).API_MSG           :=  'TOO MANY TRX_NUMBER';
                            l_transactions(i).CM_TRX_ID         :=  null;
                            l_transactions(i).CUSTOMER_TRX_ID   :=  null;
                    when    no_data_found   then
                            l_transactions(i).IS_PROCESSED      :=  'N';
                            l_transactions(i).IS_CANCELLED      :=  'E';
                            l_transactions(i).API_MSG           :=  'TRX_NUMBER NOT FOUND';
                            l_transactions(i).CM_TRX_ID         :=  null;
                            l_transactions(i).CUSTOMER_TRX_ID   :=  null;                                                
                End;
                
                if  (   l_transactions(i).customer_trx_id   is  not null    )   then
                    
                    log_step    (
                        p_package_name      =>  'XXMIP_AR_MASS_TRANS_CANCEL_PKG', 
                        p_procedure_name    =>  'START_FILE_TRANSACTION',
                        p_message           =>  'Call Api With Trx Id: '||l_transactions(i).customer_trx_id,               
                        p_api_status        =>  'S'                   
                    );    
                
                    APPS.XXMIP_AR_MASS_TRANS_CANCEL_PKG.CREDIT_INVOICE  (   
                                                        l_transactions(i).IS_CANCELLED,
                                                        l_transactions(i).API_MSG,
                                                        l_transactions(i).CM_TRX_ID,
                                                        l_transactions(i).customer_trx_id,
                                                        l_transactions(i).NOTE
                                                        --p_user_id,
                                                        --p_resp_id,
                                                        --p_resp_appl_id
                    );
                    
                    l_transactions(i).IS_PROCESSED  :=   'Y';
                    
                    log_step    (
                        p_package_name      =>  'XXMIP_AR_MASS_TRANS_CANCEL_PKG', 
                        p_procedure_name    =>  'START_FILE_TRANSACTION',
                        p_message           =>  l_transactions(i).API_MSG,               
                        p_api_status        =>  l_transactions(i).IS_CANCELLED                   
                    );
                    
                end if;
                
            end loop;  
            
            FORALL  j IN l_transactions.FIRST   ..  l_transactions.LAST  
                update  XXMIP_CANCEL_AR_INVOICES
                set
                    IS_PROCESSED        =   l_transactions(j).IS_PROCESSED,
                    IS_CANCELLED        =   l_transactions(j).IS_CANCELLED,
                    API_MSG             =   l_transactions(j).API_MSG,
                    CM_TRX_ID           =   l_transactions(j).CM_TRX_ID,
                    CUSTOMER_TRX_ID     =   l_transactions(j).CUSTOMER_TRX_ID,
                    LAST_UPDATE_DATE    =   SYSDATE
                where
                    trx_number  =   l_transactions(j).TRX_NUMBER  
                    and set_of_books_id =   l_transactions(j).SET_OF_BOOKS_ID;   
            
            
                
        end loop;    
        close   transactions;   
        commit;*/
    End start_File_Transaction; 
    
    function    get_File_Transaction_Status (   p_file_id   in  number    )   return    varchar2    is
    
    l_check number;
    l_result    varchar2(1);
    l_phase_code    varchar2(50);
    l_request_id    number;
    Begin
    
        select
            NVL(cr.phase_code,'P'),XxmipCancelArInvBatchEO.request_id   into    l_phase_code,l_request_id
        FROM 
            XXMIP.XXMIP_CANCEL_AR_INV_BATCH XxmipCancelArInvBatchEO,
            FND_CONCURRENT_REQUESTS    cr
        where
            XxmipCancelArInvBatchEO.request_id = cr.request_id(+)
            and XXMIPCANCELARINVBATCHEO.FILE_ID =   p_file_id; 
        
        if  ( l_request_id    is  not null)   then

            if  (   l_phase_code <>   'C'   )  then
            
                l_result    :=   'N';    
            
            else
            
                l_result    :=  'Y';

            end if;

            if  (   l_result <>  'N'    )    then

                select
                    count(1)    into    l_check
                from
                    XXMIP_CANCEL_AR_INVOICES
                where
                    file_id =   p_file_id
                    and (NVL(IS_CANCELLED,'E')   =   'E'   or  NVL(IS_CANCELLED,'U')   =  'U');
                                        
                if  (l_check  >   0)    then
                    l_result    :=  'Y';
                else
                    l_result    :=  'N';
                end if;    
        
            end if;
        
        else
            
            l_result    :=  'Y';
        
        end if;
        
        return  l_result;
        
    End get_File_Transaction_Status; 
    
    procedure   concurrent_Transaction  (
        retcode out varchar2,
        errbuff out varchar2,              
        p_file_id   in  number        
    )   is
    
    cursor  transactions    is
    select
        TRANSACTION_ID,
        TRX_NUMBER,
        NOTE,
        SET_OF_BOOKS_ID,
        IS_PROCESSED,
        IS_CANCELLED,
        API_MSG,
        CM_TRX_ID,
        CUSTOMER_TRX_ID        
    from
        XXMIP_CANCEL_AR_INVOICES    xxari
    where
        file_id =   p_file_id
        and ((NVL(is_processed,'N')   =   'N')   or  (is_processed   =   'Y' and NVL(IS_CANCELLED,'E')   <>  'S'));
       --  04/04/2017       
    
    type    transaction_rows    is  table   of  transactions%ROWTYPE    INDEX BY PLS_INTEGER;
    l_transactions  transaction_rows;
    
    l_credit_check  number;
    l_pay_check number;
    
    Begin
                        
        open    transactions;
        loop
            fetch   transactions    bulk    collect into    l_transactions  limit   250;               
            exit    when    l_transactions.COUNT    =   0;    
            
            for i   in  1   ..  l_transactions.COUNT    loop
                /*  STEP    1   FIND    CUSTOMER_TRX_ID */
                Begin
                    select  customer_trx_id into
                        l_transactions(i).customer_trx_id
                    from    
                        ra_customer_trx_all rt 
                    where   
                        trx_number  =   l_transactions(i).TRX_NUMBER  
                        and set_of_books_id =   l_transactions(i).SET_OF_BOOKS_ID
                        and cust_trx_type_id    =   decode(l_transactions(i).SET_OF_BOOKS_ID,1001,1000,1003,1027);    --  invoice,marine invoice                        
                exception   
                    when    too_many_rows   then
                        dbms_output.put_line('TOO_MANY_ROWS');
                            l_transactions(i).IS_PROCESSED      :=  'N';
                            l_transactions(i).IS_CANCELLED      :=  'E';
                            l_transactions(i).API_MSG           :=  'AYNI ISLEM NUMARASINA SAHIP BIRDEN FAZLA KAYIT VAR';
                            l_transactions(i).CM_TRX_ID         :=  null;
                            l_transactions(i).CUSTOMER_TRX_ID   :=  null;
                    when    no_data_found   then
                        dbms_output.put_line('no_data_found');
                            l_transactions(i).IS_PROCESSED      :=  'N';
                            l_transactions(i).IS_CANCELLED      :=  'E';
                            l_transactions(i).API_MSG           :=  'ISLEM NUMARASINA AIT FATURA BULUNAMADI';
                            l_transactions(i).CM_TRX_ID         :=  null;
                            l_transactions(i).CUSTOMER_TRX_ID   :=  null;                                                
                End;
                
                if  (   l_transactions(i).customer_trx_id   is  not null    )   then
                
                    select  
                        count(1)    into    l_credit_check
                    from
                        ra_customer_Trx_all
                    where
                        previous_customer_trx_id    =   l_transactions(i).CUSTOMER_TRX_ID;
                    
                    if  ( l_credit_check  >   0)  then
                
                        l_transactions(i).IS_PROCESSED      :=  'Y';
                        l_transactions(i).IS_CANCELLED      :=  'E';
                        l_transactions(i).API_MSG           :=  'ÝÞLEM DAHA ÖNCE ÝPTAL EDÝLMÝÞ.';
                        l_transactions(i).CM_TRX_ID         :=  null;
                    
                    else
                    
                        SELECT  
                            NVL(SUM(ARA.amount_applied),0)   into    l_pay_check     
                        FROM 
                            AR_RECEIVABLE_APPLICATIONS_ALL ARA, 
                            AR_CASH_RECEIPTS_ALL ACR, 
                            RA_CUSTOMER_TRX_ALL RCT 
                        WHERE 
                            ARA.STATUS  ='APP' 
                            AND ARA.CASH_RECEIPT_ID=ACR.CASH_RECEIPT_ID 
                            AND ARA.APPLIED_CUSTOMER_TRX_ID=RCT.CUSTOMER_TRX_ID
                            AND RCT.customer_trx_id =   l_transactions(i).CUSTOMER_TRX_ID;
                    
                        if  (   l_pay_check <>   0   )  then -- Eþleme ters çevrilince koþula uymuyor. 31032017
                    
                            l_transactions(i).IS_PROCESSED      :=  'Y';
                            l_transactions(i).IS_CANCELLED      :=  'E';
                            l_transactions(i).API_MSG           :=  'ÝÞLEM NUMARASINA AÝT EÞLEME KAYDI BULUNMAKTADIR';
                            l_transactions(i).CM_TRX_ID         :=  null;    
                        
                        else
                        
                            APPS.XXMIP_AR_MASS_TRANS_CANCEL_PKG.CREDIT_INVOICE  
                                                        (   
                                                        l_transactions(i).IS_CANCELLED,
                                                        l_transactions(i).API_MSG,
                                                        l_transactions(i).CM_TRX_ID,
                                                        l_transactions(i).customer_trx_id,
                                                        l_transactions(i).NOTE
                                                        --p_user_id,
                                                        --p_resp_id,
                                                        --p_resp_appl_id
                            );
                    
                            l_transactions(i).IS_PROCESSED  :=   'Y';     
                            
                        end if;                
                    
                    end if;        
                                                    
                end if;           
                                                
            end loop;  
            
            FORALL  j IN l_transactions.FIRST   ..  l_transactions.LAST  
                update  XXMIP_CANCEL_AR_INVOICES
                set
                    IS_PROCESSED        =   l_transactions(j).IS_PROCESSED,
                    IS_CANCELLED        =   l_transactions(j).IS_CANCELLED,
                    API_MSG             =   l_transactions(j).API_MSG,
                    CM_TRX_ID           =   l_transactions(j).CM_TRX_ID,
                    CUSTOMER_TRX_ID     =   l_transactions(j).CUSTOMER_TRX_ID,
                    LAST_UPDATE_DATE    =   SYSDATE
                where
                    trx_number  =   l_transactions(j).TRX_NUMBER  
                    and set_of_books_id =   l_transactions(j).SET_OF_BOOKS_ID and file_id = p_file_id; --31032017 güncellemede dosya numarasý eklendi.                           
                
        end loop;    
        close   transactions;   
        
        update_header_statistics(p_file_id);
        
        commit;    
    
    End concurrent_Transaction;
    
    procedure   log_step    (
        p_package_name  in  varchar2,
        p_procedure_name    in  varchar2,
        p_message   in  varchar2,
        p_api_status    in  varchar2                    
    )   is
    
    PRAGMA AUTONOMOUS_TRANSACTION;
    
    Begin
    
        insert  into    XXMIP.XXMIP_CANCEL_AR_INV_LOG   
        (
            LOG_MESSAGE, 
            PROCEDURE, 
            PACKAGE, 
            CREATION_DATE, 
            STATUS
        )
        values  
        (
            p_message,
            p_procedure_name,
            p_package_name,
            SYSDATE,
            p_api_status
        );
    
        commit;
        
    End log_step ;
    
    procedure   update_header_statistics    (
        p_file_id  in  number
    ) is
    
    Begin
    
        update  XXMIP.XXMIP_CANCEL_AR_INV_BATCH 
        set NUMBER_OF_ERROR_ROWS    =   
            (
                select 
                    count(1) 
                from   
                    XXMIP.XXMIP_CANCEL_AR_INVOICES  
                where   
                    file_id =   p_file_id
                    and CM_TRX_ID   is  null
            )
        where   file_id =   p_file_id;            
    
    End update_header_statistics; 
    
    procedure   update_tax_lines_ccid   (
        p_cust_trx_id   in  number,
        p_cm_trx_id     in  number
    )   is
    
    cursor  rows_to_update  is
    select  
        r1.customer_trx_line_id as  customer_trx_line_id,
        r1.customer_trx_id,
        r2.customer_trx_line_id as  cm_trx_line_id,
        r2.customer_trx_id  as  cm_trx_id
    from    
        ra_customer_Trx_lines_all   r1,
        ra_customer_Trx_lines_all   r2   
    where   
        r1.customer_trx_id      =   p_cust_trx_id  
        and r2.customer_trx_id  =   p_cm_trx_id           
        and r1.customer_trx_line_id =   r2.previous_customer_trx_line_id
        and r1.line_type        =   'TAX'
        and r2.line_type        =   'TAX';
        
        l_ref_ccid  number;
        l_orj_ccid  number;
        l_orj_record_id number;
        
    Begin
    
        for sel in  rows_to_update  loop
            
            select
                CODE_COMBINATION_ID    into    l_ref_ccid
            from
            (
                select  
                    max(CUST_TRX_LINE_GL_DIST_ID)   over    (partition  by  customer_trx_line_id)  max_record_id,
                    CUST_TRX_LINE_GL_DIST_ID    record_id,
                    CODE_COMBINATION_ID
                from
                    RA_CUST_TRX_LINE_GL_DIST_ALL
                where
                    customer_trx_line_id    =   sel.customer_trx_line_id
            )
            where
                record_id   =   max_record_id;
            
            select
                CODE_COMBINATION_ID,record_id    into    l_orj_ccid,l_orj_record_id
            from
            (
                select  
                    max(CUST_TRX_LINE_GL_DIST_ID)   over    (partition  by  customer_trx_line_id)   max_record_id,
                    CUST_TRX_LINE_GL_DIST_ID    record_id,
                    CODE_COMBINATION_ID
                from
                    RA_CUST_TRX_LINE_GL_DIST_ALL
                where
                    customer_trx_line_id    =   sel.cm_trx_line_id
            )
            where
                record_id   =   max_record_id;
        
            update  RA_CUST_TRX_LINE_GL_DIST_ALL    
                set CODE_COMBINATION_ID    =   l_ref_ccid,
                    attribute1  =   l_orj_ccid
            where   
                CUST_TRX_LINE_GL_DIST_ID    =   l_orj_record_id;                       
        
        end loop;
    
    end update_tax_lines_ccid;
    
end XXMIP_AR_MASS_TRANS_CANCEL_PKG;
/