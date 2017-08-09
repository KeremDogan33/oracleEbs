CREATE OR REPLACE PACKAGE APPS.XXMIP_AR_MASS_TRANS_CANCEL_PKG  as          
    
    procedure   credit_invoice  (
            x_api_status    out varchar2,
            x_message   out varchar2,
            x_credit_trx_id     out number,
            p_customer_trx_id   in  number,
            p_cancellation_note in  varchar2
            --p_user_id   in  number,
            --p_resp_id   in  number,
            --p_resp_appl_id  in  number                        
    );
    
    function calc_line_tax_amount (p_customer_trx_line_id in number)    return number;
    
    function get_memo_trx_id (   p_req_id in number  )  return number;
    
    procedure   start_File_Transaction    (     
                                                x_request_id    out varchar2,
                                                p_file_id  in  varchar2,
                                                p_user_id   in  number,
                                                p_resp_id   in  number,
                                                p_resp_appl_id  in  number
    );
    
    function    get_File_Transaction_Status (   p_file_id   in  number    )   return    varchar2;    
    
    procedure   concurrent_Transaction  (
        retcode out varchar2,
        errbuff out varchar2,
        p_file_id   in  number        
    );
    
    procedure   log_step    (
        p_package_name  in  varchar2,
        p_procedure_name    in  varchar2,
        p_message   in  varchar2,
        p_api_status    in  varchar2                    
    );
    
    procedure   update_header_statistics    (
        p_file_id  in  number
    );
    
    procedure   update_tax_lines_ccid   (
        p_cust_trx_id   in  number,
        p_cm_trx_id in  number
    );
        
end XXMIP_AR_MASS_TRANS_CANCEL_PKG;
/