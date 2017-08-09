CREATE OR REPLACE PACKAGE APPS.XXMIP_AR_MASS_CM_PKG    as
    
    Procedure   concurrent_transaction  (
                                errbuff out varchar2,
                                retcode out varchar2,
                                p_header_id in  number,
                                p_responsibility_id in  number,
                                p_function_param    in  varchar2
    );        
    
    function    check_currency_per_trx (
        p_trx_number    in  varchar2,
        p_sob_id        in  number,
        p_header_id     in  number
    )   return  varchar2;
        
    
    procedure   credit_invoice  (
            x_api_status        out varchar2,
            x_message           out varchar2,
            x_credit_trx_id     out number,
            p_trx_number   in  varchar2,
            p_sob_id    in  number,
            p_header_id in  number                
    );
    
    function    get_memo_trx_id (p_request_id   in  number) return  number;
    
    function    check_credit_amount_per_line    (
            p_customer_Trx_line_id   in  number,
            p_trx_line_number   in  number                                
    )   return  number;
    
    procedure   validate_lines  (
        x_status    out varchar2,
        x_error_msg out varchar2, 
        p_trx_number   in  varchar2,
        p_sob_id    in  number,
        p_header_id in  number   
    );    
            
    procedure    get_item_memo (
        x_memo_line_id  out number,
        p_item_description  in  varchar2
    );   
    
    procedure   check_header  (
        x_status    out varchar2,
        x_error_msg out varchar2,
        p_paper_num in  varchar2,
        p_header_id in  number    
    );
    
    function    get_total_applied_receipt   (
        p_customer_trx_id   in  number   
    )   return  number;
    
    procedure   check_transaction   (
        x_status    out varchar2,
        x_error_msg    out varchar2,
        p_header_id in  number,
        p_Trx_number    in  varchar2,
        p_sob_id    in  number             
    );
    
    procedure   check_file  (
        errbuff    out varchar2,
        retcode out varchar2,
        p_header_id in  number,
        p_responsibility_id in  number,
        p_function_param    in  varchar2            
    );
    
END XXMIP_AR_MASS_CM_PKG;
/