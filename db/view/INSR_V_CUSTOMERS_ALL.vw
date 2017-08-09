/* Formatted on 07.08.2017 13:17:38 (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW XXMIP.INSR_V_CUSTOMERS_ALL
(
   PARTY_ID,
   PARTY_NAME
)
AS
   SELECT hp.party_id, hp.party_name
     FROM apps.hz_parties hp
    WHERE     status = 'A'
          AND EXISTS
                 (SELECT 1
                    FROM apps.HZ_CUST_ACCOUNTS hzc
                   WHERE hzc.party_id = hp.party_id AND hzc.status = 'A');
