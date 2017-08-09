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
        Responsibility_ID   --  Güvenlik Doðrulamasý
        Dosya Tipi          --  Dosya Tipi
        
        Açýklama:            
            *   XLS arayüz tablolarýndaki verileri eþleþtirme tablosundaki tablo-kolon verilerine göre  tabloya atar
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
        x_cursor,           --  global cursor ileride dbms_sql library için gerekli
        x_table_name        --  ilgili dosyaya atalý tablo ismi
        x_query             --  global cursor select statement
        Dosya Id,           --  Global Header   PK
        Responsibility_ID   --  Güvenlik Doðrulamasý
        Dosya Tipi          --  Dosya Tipi
        
        Açýklama:            
            *   Eþleþtirme tablosundaki verilere göre bir select statement oluþturur. Ana prosedür tarafýndan çaðrýlýr                
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
        
        Dönüþ:
            Y   --  Dosya Ýçeriði Yürütülebilir
            N   --  Dosya Ýçeriði Yürütülemez
        
        Açýklama:           
            *   Dosyanýn güvenlik tablosundaki eþ zamanlý program tarafýndan yürütülebilir statüdede olup olmadýðýný hesaplar                
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
        
        Açýklama:           
            *   Dosya baþlýk tablosunda iþleme statü güncellemesini yapar.                
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
        
        Açýklama:           
            *   Ýlgili parametrelerde bir dosya olup olmadýðýný kontrol eden prosedür    
            *   Dosyanýn iþlenmeye hazýr olup olmadýðýný denetler          
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
            p_lines_result  --  Satýr ve statüleri tutan collection tipi        
        
        Açýklama:           
            *   Global arayüz satýr tablosundaki verilerin güncellenmesi           
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