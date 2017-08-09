/* Formatted on 07.08.2017 13:17:13 (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW XXMIP.INSR_FIRM_LIST_V
(
   FIRM_ID,
   FIRM_NAME,
   FIRM_TYPE,
   POPLIST_ID
)
AS
   SELECT PARTY_ID AS FIRM_ID,
          PARTY_NAME AS FIRM_NAME,
          'Customer' AS FIRM_TYPE,
          val_set.insr_value_line_id AS POPLIST_ID
     FROM XXMIP.INSR_V_CUSTOMERS_ALL cust,
          (SELECT value_name, insr_value_line_id
             FROM XXMIP.INSR_VALUE_LINES_ALL
            WHERE INSR_VALUE_HEADER_ID = (SELECT insr_value_header_id
                                            FROM XXMIP.INSR_VALUE_HEADERS_ALL
                                           WHERE VALUE_NAME = 'FRMTYP'))
          val_set
    WHERE 'Customer' = val_set.VALUE_NAME
   UNION ALL
   SELECT VENDOR_ID AS FIRM_ID,
          VENDOR_NAME AS FIRM_NAME,
          'Supplier' AS FIRM_TYPE,
          val_set.insr_value_line_id AS POPLIST_ID
     FROM XXMIP.INSR_V_SUPPLIERS_ALL supp,
          (SELECT value_name, insr_value_line_id
             FROM XXMIP.INSR_VALUE_LINES_ALL
            WHERE INSR_VALUE_HEADER_ID = (SELECT insr_value_header_id
                                            FROM XXMIP.INSR_VALUE_HEADERS_ALL
                                           WHERE VALUE_NAME = 'FRMTYP'))
          val_set
    WHERE 'Supplier' = val_set.VALUE_NAME
   UNION ALL
   SELECT CUSTOM_LIST.FIRM_ID,
          CUSTOM_LIST.FIRM_NAME,
          CUSTOM_LIST.FIRM_TYPE,
          val_set.insr_value_line_id AS POPLIST_ID
     FROM (SELECT insr_value_line_id AS FIRM_ID,
                  value_name AS FIRM_NAME,
                  'MIP Custom' AS FIRM_TYPE
             FROM XXMIP.INSR_VALUE_LINES_ALL
            WHERE INSR_VALUE_HEADER_ID = (SELECT insr_value_header_id
                                            FROM XXMIP.INSR_VALUE_HEADERS_ALL
                                           WHERE VALUE_NAME = 'BNFCRY'))
          CUSTOM_LIST,
          (SELECT value_name, insr_value_line_id
             FROM XXMIP.INSR_VALUE_LINES_ALL
            WHERE INSR_VALUE_HEADER_ID = (SELECT insr_value_header_id
                                            FROM XXMIP.INSR_VALUE_HEADERS_ALL
                                           WHERE VALUE_NAME = 'FRMTYP'))
          val_set
    WHERE 'MIP Custom' = val_set.VALUE_NAME;


CREATE OR REPLACE SYNONYM APPS.XXMIP_INSR_FIRM_LIST_V FOR XXMIP.INSR_FIRM_LIST_V;
