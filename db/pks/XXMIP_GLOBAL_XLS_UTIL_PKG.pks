CREATE OR REPLACE PACKAGE APPS.XXMIP_GLOBAL_XLS_UTIL_PKG   as                        
        
    l_interface_table_name   varchar2(250)   :=  'XXMIP.XLS_GLOBAL_INTERFACE_LINES';
        
    type    interface_line_status_rec_type  is  RECORD  (
        header_id   number,
        interface_line_id   number,
        success_flag    varchar2(1),
        error_msg   varchar2(4000)
    );
    
    type    interface_line_status_tbl_type  is  table   of  interface_line_status_rec_type  index   by  binary_integer;  
    /*
        Concurrent Procedure
        Dosya Id,           --  Global Header   PK
        Responsibility_ID   --  G�venlik Do�rulamas�
        Dosya Tipi          --  Dosya Tipi
        
        A��klama:            
            *   XLS aray�z tablolar�ndaki verileri e�le�tirme tablosundaki tablo-kolon verilerine g�re  tabloya atar
    */

    procedure   file_transaction    (   
                                    errbuf  out varchar2,
                                    retcode out varchar2,
                                    p_header_id in  number,
                                    p_resp_id   in  number,
                                    p_function_param    in  varchar2                                    
    );
    
    /*
        get_ref_cursor Procedure
        x_cursor,           --  global cursor ileride dbms_sql library i�in gerekli
        x_table_name        --  ilgili dosyaya atal� tablo ismi
        x_query             --  global cursor select statement
        Dosya Id,           --  Global Header   PK
        Responsibility_ID   --  G�venlik Do�rulamas�
        Dosya Tipi          --  Dosya Tipi
        
        A��klama:            
            *   E�le�tirme tablosundaki verilere g�re bir select statement olu�turur. Ana prosed�r taraf�ndan �a�r�l�r                
    */
    
    procedure   get_ref_cursor  (   
                                x_cursor    out sys_refcursor,
                                x_table_name    out varchar2,
                                x_query out varchar2,                                
                                p_function_param    in  varchar2,
                                p_resp_id   in  number,
                                p_header_id    in  number                                
    );        
    
    /*
        get_file_transaction_status Function
        
        Parametre:
            p_header_id     --  Global Header   PK
        
        D�n��:
            Y   --  Dosya ��eri�i Y�r�t�lebilir
            N   --  Dosya ��eri�i Y�r�t�lemez
        
        A��klama:           
            *   Dosyan�n g�venlik tablosundaki e� zamanl� program taraf�ndan y�r�t�lebilir stat�dede olup olmad���n� hesaplar                
    */    
    function    get_file_transaction_status (
        p_header_id in  number
    )   return  varchar2;        
    /*
        set_header_process_status Procedure
        
        Parametre:
            p_header_id     --  Global Header   PK
            p_request_id    --  Execution   Request Id
            p_status    --  Status to Update        
        
        A��klama:           
            *   Dosya ba�l�k tablosunda i�leme stat� g�ncellemesini yapar.                
    */    
    procedure   set_header_process_status  (
        p_header_id in  number,
        p_request_id    in  number,
        p_status    in  varchar2
    );
    /*
        validate_parameters Procedure
        
        Parametre:
            p_header_id     --  Global Header   PK
            p_responsibility_id    --  Sorumluluk   Id
            p_function_param    --  Dosya Tipi
            
            x_status    --  out parameter
            x_error_msg --  validation  message out parameter
        
        A��klama:           
            *   �lgili parametrelerde bir dosya olup olmad���n� kontrol eden prosed�r    
            *   Dosyan�n i�lenmeye haz�r olup olmad���n� denetler          
    */ 
    procedure   validate_parameters   (
        x_status    out varchar2,
        x_error_msg out varchar2,        
        p_header_id in  number,
        p_responsibility_id in  number,
        p_function_param    in  varchar2    
    );
    /*
        set_lines_status Procedure
        
        Parametre:
            p_lines_result  --  Sat�r ve stat�leri tutan collection tipi        
        
        A��klama:           
            *   Global aray�z sat�r tablosundaki verilerin g�ncellenmesi           
    */ 
    procedure   set_lines_status    (
        p_lines_result  in  interface_line_status_tbl_type        
    );
    
    procedure   save_header_mapping (
        p_header_id in  number,
        p_resp_id   in  number,
        p_function_param    in  varchar2
    );
    
END XXMIP_GLOBAL_XLS_UTIL_PKG;
/