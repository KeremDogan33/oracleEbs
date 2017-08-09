/* Formatted on 07.08.2017 11:36:55 (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW APPS.XXMIP_INSR_INVOICES_V
(
   INVOICE_ID,
   INVOICE_NUM,
   VENDOR_ID,
   INVOICE_AMOUNT,
   INVOICE_DATE,
   DESCRIPTION,
   INVOICE_STATUS,
   VENDOR_NAME,
   ORG_ID,
   INVOICE_CURRENCY_CODE
)
AS
   SELECT invoice_id,
          invoice_num,
          pov.vendor_id,
          invoice_amount,
          invoice_date,
          description,
          apps.AP_INVOICES_PKG.GET_APPROVAL_STATUS (
             ai.invoice_id,
             ai.invoice_amount,
             ai.payment_status_flag,
             ai.invoice_type_lookup_code)
             AS inv_status,
          pov.vendor_name,
          ai.org_id,
          ai.INVOICE_CURRENCY_CODE
     FROM ap.ap_invoices_all ai, apps.po_vendors pov
    WHERE     ai.vendor_id = pov.vendor_id
          AND ai.INVOICE_TYPE_LOOKUP_CODE <> 'CREDIT';
