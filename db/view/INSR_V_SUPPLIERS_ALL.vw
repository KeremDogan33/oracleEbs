/* Formatted on 07.08.2017 13:18:08 (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW XXMIP.INSR_V_SUPPLIERS_ALL
(
   VENDOR_ID,
   VENDOR_NAME
)
AS
   SELECT vendor_id, vendor_name
     FROM apps.ap_suppliers
    WHERE end_date_active IS NULL;
