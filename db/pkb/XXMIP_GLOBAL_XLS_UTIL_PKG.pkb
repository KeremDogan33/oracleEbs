CREATE OR REPLACE PACKAGE BODY APPS.XXMIP_GLOBAL_XLS_UTIL_PKG   as
    
    procedure   file_transaction    (   
                                    errbuf  out varchar2,
                                    retcode out varchar2,
                                    p_header_id in  number,
                                    p_resp_id   in  number,
                                    p_function_param    in  varchar2                                    
    )   is
    
    TYPE XLS_DATA IS REF CURSOR;    
    xls_rows    XLS_DATA;
    l_query     varchar2(4000);
    v_desc       DBMS_SQL.DESC_TAB;
    
    l_table_name    varchar2(150);    
    curid   NUMBER;
    colcnt  number;
 
    l_insert_statement  varchar2(32767);    
    l_select_statement  varchar2(32767);
    l_delete_stmt   varchar2(32767);
    
    Begin
        
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,''';
        
        fnd_file.put_line(fnd_file.log,'******Parameters*******');
        fnd_file.put_line(fnd_file.log,'p_header_id: '||p_header_id);
        fnd_file.put_line(fnd_file.log,'p_resp_id: '||p_resp_id);
        fnd_file.put_line(fnd_file.log,'p_function_param: '||p_function_param);                  

        XXMIP_GLOBAL_XLS_UTIL_PKG.get_ref_cursor    ( 
            x_cursor            =>  xls_rows,
            x_table_name        =>  l_table_name, 
            x_query             =>  l_query,                       
            p_function_param    =>  p_function_param,
            p_resp_id           =>  p_resp_id,      
            p_header_id         =>  p_header_id
        );
        
        if  (l_table_name  is  not null)   then
        
            l_delete_stmt   :=  'DELETE FROM '||l_table_name||' where header_id = '||p_header_id;
            execute immediate(l_delete_stmt);
            
            Begin
                                            
                fnd_file.put_line(fnd_file.log,'l_table_name: '||l_table_name);
        
                l_insert_statement  :=  'INSERT INTO '||l_table_name||' (';                
                        
                curid := DBMS_SQL.to_cursor_number (xls_rows);                    
                
                DBMS_SQL.describe_columns (curid, colcnt, v_desc); 
                
                FOR indx IN 1 .. colcnt LOOP                                                                                                            
                
                    l_insert_statement  :=  l_insert_statement  ||v_desc (indx).col_name||',';
            
                END LOOP;
                               
                l_insert_statement  :=  SUBSTR(l_insert_statement, 1, LENGTH(l_insert_statement) - 1);
                l_insert_statement  :=  l_insert_statement||')';        
                l_select_statement  :=  l_insert_statement||' '||l_query;
                                  
                fnd_file.put_line(fnd_file.log,'STATEMENT: '||l_select_statement);
                execute immediate(l_select_statement);                         
                DBMS_SQL.close_cursor (curid);    
                
                fnd_file.put_line(fnd_file.OUTPUT,'DOSYA BAÞARILI BÝR ÞEKÝLDE YÜKLENDÝ');
                
                update  XXMIP.XLS_GLOBAL_HEADER_INTERFACE   
                set 
                    load_request_id  =   fnd_global.CONC_REQUEST_ID,
                    is_loaded   =   'Y'
                where   header_id   =   p_header_id;
                
                save_header_mapping (   --  save    used    mapping for     that    header  /*  29.05.2017  */
                    p_header_id =>  p_header_id,                      
                    p_resp_id   =>  p_resp_id,  
                    p_function_param    =>  p_function_param        
                );  
                                 
            exception   when    others  then
        
                if  (DBMS_SQL.IS_OPEN(curid)) then        
                    DBMS_SQL.close_cursor (curid); 
                end if;
                errbuf  :=  sqlerrm;
                retcode :=  2;  
                
                update  XXMIP.XLS_GLOBAL_HEADER_INTERFACE   
                set 
                    load_request_id  =   fnd_global.CONC_REQUEST_ID,
                    is_loaded   =   'N'
                where   header_id   =   p_header_id; 
                
                fnd_file.put_line(fnd_file.OUTPUT,'DOSYA YÜKLENÝRKEN HATA OLUÞTU');
                fnd_file.put_line(fnd_file.OUTPUT,'HATA MESAJI '||sqlerrm);
                
            End;
                                 
        else
            
            errbuf  :=  'SQL OLUÞTURULURKEN HATA OLUÞTU';
            retcode :=  2;  
        
            update  XXMIP.XLS_GLOBAL_HEADER_INTERFACE   
            set 
                load_request_id  =   fnd_global.CONC_REQUEST_ID,
                is_loaded   =   'N'
            where   
                header_id   =   p_header_id;
            
            fnd_file.put_line(fnd_file.OUTPUT,'DOSYA YÜKLENÝRKEN HATA OLUÞTU');
            fnd_file.put_line(fnd_file.OUTPUT,'LOG DOSYASINI ÝNCELE');
            fnd_file.put_line(fnd_file.OUTPUT,'HATA MESAJI: '||errbuf);

        end if;
            
        commit;
                       
    exception   when    others  then
        
        if  (DBMS_SQL.IS_OPEN(curid)) then        
            DBMS_SQL.close_cursor (curid); 
        end if;
        errbuf  :=  sqlerrm;
        retcode :=  2;  
        
        update  XXMIP.XLS_GLOBAL_HEADER_INTERFACE   
        set 
            load_request_id  =   fnd_global.CONC_REQUEST_ID,
            is_loaded   =   'E'
        where   header_id   =   p_header_id; 
        
        commit;
            
    End file_transaction; 
    
    procedure   get_ref_cursor    (   
                                x_cursor    out sys_refcursor,
                                x_table_name    out varchar2,
                                x_query out varchar2,                                
                                p_function_param    in  varchar2,
                                p_resp_id   in  number,
                                p_header_id    in  number                                
    )   is        
    
    cursor  mapping_row    is    
        select  
            xls_mapping.SCHEMA,
            xls_mapping.TABLE_NAME,
            xls_mapping.XLS_COLUMN,
            xls_mapping.COLUMN_FIELD_NAME,
            xls_mapping.COLUMN_FIELD_TYPE,
            xls_mapping.RECORD_ID
        from            
            xxmip.XLS_GLOBAL_INTERFACE_MAPPING    xls_mapping
        where   
            function_param      =   p_function_param
            and resp_id         =   p_resp_id
            and enabled_flag    =   'Y'
        order   by  record_id;
    
    type    map_rows    is  table   of  mapping_row%ROWTYPE;    
    l_mappings  map_rows;
        
    l_select_stmt   varchar2(32767);               
    l_format_sql    varchar2(32767);
    
    l_format_length number;
    l_format_mask   varchar2(150)   :=  '.99999';
    
    loops number := 1;
    
    Begin
        
        l_select_stmt   :=  'SELECT INTERFACE_LINE_ID,HEADER_ID,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY,LAST_UPDATE_LOGIN, ';
    
        open    mapping_row;
        loop
            fetch   mapping_row bulk    collect into    l_mappings  limit   250;
            exit    when    l_mappings.COUNT    =   0;
            
            for i   in  1   ..  l_mappings.COUNT    loop                
                x_table_name    :=  l_mappings(i).SCHEMA||'.'||l_mappings(i).TABLE_NAME;                 
                case    l_mappings(i).COLUMN_FIELD_TYPE    
                when    'NUMBER'    then     
                    
                    l_format_sql   :=  'select  max(length('||l_mappings(i).XLS_COLUMN||')) from '||XXMIP_GLOBAL_XLS_UTIL_PKG.l_interface_table_name||' where  header_id = '||p_header_id||' AND NVL(SUCCESS_FLAG,''E'')=''E''  ';                        
                    execute immediate l_format_sql into l_format_length;                        
                        
                    while loops <= l_format_length loop
                        l_format_mask   :=  '9'||l_format_mask; 
                        loops   :=  loops+1;                           
                    end loop;
                        
                    l_select_stmt   :=  l_select_stmt||' to_number('||l_mappings(i).XLS_COLUMN||','||''||l_format_mask||''||','||'''NLS_NUMERIC_CHARACTERS='''',.'''''') as '||l_mappings(i).COLUMN_FIELD_NAME||',';
                when    'DATE' then
                    l_select_stmt   :=  l_select_stmt||' to_date('||l_mappings(i).XLS_COLUMN||',''MM/DD/YYYY HH24:MI:SS'') as '||l_mappings(i).COLUMN_FIELD_NAME||',';  --java.sql.date
                else
                    l_select_stmt   :=  l_select_stmt||' '||l_mappings(i).XLS_COLUMN||' as '||l_mappings(i).COLUMN_FIELD_NAME||',';                    
                end case;            
            end loop;
        
        end loop;
        close   mapping_row;
        
        l_select_stmt   :=  SUBSTR(l_select_stmt, 1, LENGTH(l_select_stmt) - 1);
        l_select_stmt   :=  l_select_stmt||' from '||XXMIP_GLOBAL_XLS_UTIL_PKG.l_interface_table_name||' where  header_id = '||p_header_id||' AND NVL(SUCCESS_FLAG,''E'')=''E''  ';                               

        fnd_file.put_line(fnd_file.log,'l_select_stmt: '||l_select_stmt);
                    
        x_query :=  l_select_stmt;
        
        open    x_cursor    for l_select_stmt;                                   
    
    exception   when    others  then
        x_cursor        :=  null;
        x_query         :=  null;
        x_table_name    :=  null;
        
        fnd_file.put_line(fnd_file.log,'Error Getting Insert Statement: '||sqlerrm);
    
    End get_ref_cursor;                 
    
    function    get_file_transaction_status (
        p_header_id in  number
    )   return  varchar2    is
    
    l_process_status    varchar2(1);
    l_load_status   varchar2(1);
    l_return    varchar2(1);
    l_check number;
    
    l_concurrent_name   XXMIP.XLS_GLOBAL_SECURITY_MAPPING.CONCURRENT_SHORT_NAME%TYPE;
    
    Begin
        
        select  
            NVL(IS_LOADED,'N')   into    l_load_status
        from
            XXMIP.XLS_GLOBAL_HEADER_INTERFACE
        where
            HEADER_ID   =   p_header_id;        
        
        if  (   l_load_status   in   ('N' ,'E' ))    then
            
            l_return    :=  'N';    --  not loaded yet
        
        else   
        
            select
                NVL(IS_PROCESSED,'N')   into    l_process_status
            from
                XXMIP.XLS_GLOBAL_HEADER_INTERFACE
            where
                header_id   =   p_header_id;
            
            if  (   l_process_status  =    'N'  )   then    --  not processed
                                            
                select  
                    MAPPINGS.CONCURRENT_SHORT_NAME  into    l_concurrent_name
                from
                    XXMIP.XLS_GLOBAL_HEADER_INTERFACE   headers,
                    XXMIP.XLS_GLOBAL_SECURITY_MAPPING   mappings
                where
                    header_id   =   p_header_id
                    and HEADERS.FUNCTION_PARAM  =   MAPPINGS.FILE_PARAM(+)
                    and HEADERS.RESP_ID =   MAPPINGS.RESP_ID(+);    
                
                if  (   l_concurrent_name   is  not null    )   then
                    l_return    :=  'Y';
                else
                    l_return    :=  'N';
                end if;
                
            elsif   (   l_process_status    =   'E')    then    --  concurrent  not finished
            
                l_return    :=  'N';
            
            else    --  concurrent  finished    with    errors
            
                select  count(1)    into    l_check
                from
                    XXMIP.XLS_GLOBAL_INTERFACE_LINES
                where
                    header_id   =   p_header_id
                    and NVL(SUCCESS_FLAG,'E')  =   'E'; 
            
                if  (l_check  >   0)  then
            
                    select  
                        MAPPINGS.CONCURRENT_SHORT_NAME  into    l_concurrent_name
                    from
                        XXMIP.XLS_GLOBAL_HEADER_INTERFACE   headers,
                        XXMIP.XLS_GLOBAL_SECURITY_MAPPING   mappings
                    where
                        header_id   =   p_header_id
                        and HEADERS.FUNCTION_PARAM  =   MAPPINGS.FILE_PARAM(+)
                        and HEADERS.RESP_ID =   MAPPINGS.RESP_ID(+);    
                    
                    if  (   l_concurrent_name   is  not null    )   then
                        l_return    :=  'Y';
                    else
                        l_return    :=  'N';
                    end if;
            
                else
                
                    l_return    :=  'N';

                end if;
            
            end if;
                                    
        end if;

        return  l_return;

    End get_file_transaction_status; 
    
    
    procedure   set_header_process_status  (
        p_header_id in  number,
        p_request_id    in  number,
        p_status    in  varchar2
    )   is
    
    PRAGMA AUTONOMOUS_TRANSACTION;
    
    Begin
        
        update  
            XXMIP.XLS_GLOBAL_HEADER_INTERFACE   
        set 
            is_processed    =   p_status,
            REQUEST_ID  =   p_request_id    
        where   
            header_id   =   p_header_id;
        
        commit;             
    
    End set_header_process_status;
    
    procedure   validate_parameters   (
        x_status    out varchar2,
        x_error_msg out varchar2,        
        p_header_id in  number,
        p_responsibility_id in  number,
        p_function_param    in  varchar2    
    )   is
    
    l_file_name varchar2(500);
    l_load_flag varchar2(1);
    l_load_request_id   number;
    l_header_id number;
    
    Begin
        
        x_status    :=  'SUCCESS';
        x_error_msg :=  null;
        
        Begin
            
            select
                file_name,
                NVL(is_loaded,'N')  as  load_flag,
                load_request_id,
                header_id
            into    
                l_file_name,
                l_load_flag,
                l_load_request_id,
                l_header_id            
            from
                xxmip.xls_global_header_interface
            where
                header_id   =   p_header_id
                and resp_id =   p_responsibility_id
                and function_param  =   p_function_param; 
        
        exception   when    no_data_found   then
            x_status    :=  'ERROR';
            x_error_msg :=  'GEÇERSÝZ PARAMETRE- DOSYA BULUNAMADI';            
        End;
        
        if  (   x_status    =   'SUCCESS'   )   then
        
            if  (   l_load_flag    <>   'Y' )   then
                    
                x_status    :=  'ERROR';
                x_error_msg :=  'GEÇERSÝZ PARAMETRE- DOSYA HENÜZ UYGULAMA TABLOSUNA AKTARILMADI';                                                    
                    
            end if;
        
        end if;
        
    End validate_parameters; 
    
    procedure   set_lines_status    (
        p_lines_result  in  interface_line_status_tbl_type        
    )   is    
        
    PRAGMA AUTONOMOUS_TRANSACTION;
    
    Begin
    
        FORALL i IN 1..p_lines_result.COUNT
            UPDATE  XXMIP.XLS_GLOBAL_INTERFACE_LINES   
            set 
                SUCCESS_FLAG    =   p_lines_result(i).SUCCESS_FLAG,
                ERROR_MSG       =   p_lines_result(i).ERROR_MSG,
                LAST_UPDATE_DATE    =   SYSDATE,
                LAST_UPDATE_LOGIN   =   fnd_global.login_id       
            where
                interface_line_id   =   p_lines_result(i).INTERFACE_LINE_ID;                   
        commit;        

    End set_lines_status; 
    
    procedure   save_header_mapping (
        p_header_id in  number,
        p_resp_id   in  number,
        p_function_param    in  varchar2
    )   is
    
    l_check number;
    
    Begin
        
        select  count(1)    into    l_check
        from
            XXMIP.XLS_GLOBAL_HEADER_MAPPING_USG
        where
            header_id   =   p_header_id;

        if  ( l_check =   0)  then
            
            insert  into    XXMIP.XLS_GLOBAL_HEADER_MAPPING_USG 
            (
                HEADER_ID,
                "SCHEMA",
                TABLE_NAME,
                XLS_COLUMN,
                COLUMN_FIELD_NAME,
                COLUMN_FIELD_TYPE,
                RECORD_ID,
                XLS_COLUMN_USER_NAME,
                REQUIRED,
                CREATION_DATE,
                CREATED_BY,
                LAST_UPDATE_DATE,
                LAST_UPDATED_BY,
                LAST_UPDATE_LOGIN            
            )    
            select  
                p_header_id,    
                xls_mapping.SCHEMA,
                xls_mapping.TABLE_NAME,
                xls_mapping.XLS_COLUMN,
                xls_mapping.COLUMN_FIELD_NAME,
                xls_mapping.COLUMN_FIELD_TYPE,
                xls_mapping.RECORD_ID,
                XLS_COLUMN_USER_NAME,
                REQUIRED,
                SYSDATE,
                NVL(fnd_global.USER_ID,-1),
                SYSDATE,
                NVL(fnd_global.USER_ID,-1),
                NVL(fnd_global.LOGIN_ID,-1)
            from            
                xxmip.XLS_GLOBAL_INTERFACE_MAPPING    xls_mapping
            where   
                function_param      =   p_function_param
                and resp_id         =   p_resp_id
                and enabled_flag    =   'Y';
        
        else
        
            delete  from    XXMIP.XLS_GLOBAL_HEADER_MAPPING_USG where   header_id   =   p_header_id;
            
            insert  into    XXMIP.XLS_GLOBAL_HEADER_MAPPING_USG 
            (
                HEADER_ID,
                "SCHEMA",
                TABLE_NAME,
                XLS_COLUMN,
                COLUMN_FIELD_NAME,
                COLUMN_FIELD_TYPE,
                RECORD_ID,
                XLS_COLUMN_USER_NAME,
                REQUIRED,
                CREATION_DATE,
                CREATED_BY,
                LAST_UPDATE_DATE,
                LAST_UPDATED_BY,
                LAST_UPDATE_LOGIN            
            )    
            select  
                p_header_id,    
                xls_mapping.SCHEMA,
                xls_mapping.TABLE_NAME,
                xls_mapping.XLS_COLUMN,
                xls_mapping.COLUMN_FIELD_NAME,
                xls_mapping.COLUMN_FIELD_TYPE,
                xls_mapping.RECORD_ID,
                xls_mapping.XLS_COLUMN_USER_NAME,
                xls_mapping.REQUIRED,
                SYSDATE,
                NVL(fnd_global.USER_ID,-1),
                SYSDATE,
                NVL(fnd_global.USER_ID,-1),
                NVL(fnd_global.LOGIN_ID,-1)
            from            
                xxmip.XLS_GLOBAL_INTERFACE_MAPPING    xls_mapping
            where   
                function_param      =   p_function_param
                and resp_id         =   p_resp_id
                and enabled_flag    =   'Y';
                     
        end if;            
    
    End save_header_mapping; 
    
END XXMIP_GLOBAL_XLS_UTIL_PKG;
/