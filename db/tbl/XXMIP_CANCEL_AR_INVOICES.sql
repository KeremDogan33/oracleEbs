CREATE TABLE XXMIP.XXMIP_CANCEL_AR_INVOICES
(
  TRX_NUMBER         VARCHAR2(150 BYTE),
  NOTE               VARCHAR2(500 BYTE),
  FILE_ID            NUMBER,
  TRANSACTION_ID     NUMBER,
  IS_CANCELLED       VARCHAR2(1 BYTE),
  API_MSG            VARCHAR2(4000 BYTE),
  CREATION_DATE      DATE,
  CREATED_BY         NUMBER,
  LAST_UPDATE_DATE   DATE,
  LAST_UPDATED_BY    NUMBER,
  LAST_UPDATE_LOGIN  NUMBER,
  SET_OF_BOOKS_ID    NUMBER,
  IS_PROCESSED       VARCHAR2(1 BYTE),
  CM_TRX_ID          NUMBER,
  CUSTOMER_TRX_ID    NUMBER
)
TABLESPACE SYSTEM
PCTUSED    40
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          16K
            NEXT             16K
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       505
            PCTINCREASE      50
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;


CREATE UNIQUE INDEX XXMIP.XXMIP_CANCEL_AR_INVOICES_PK ON XXMIP.XXMIP_CANCEL_AR_INVOICES
(TRANSACTION_ID)
LOGGING
TABLESPACE SYSTEM
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          16K
            NEXT             16K
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       505
            PCTINCREASE      50
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           );

CREATE OR REPLACE SYNONYM APPS.XXMIP_CANCEL_AR_INVOICES FOR XXMIP.XXMIP_CANCEL_AR_INVOICES;


ALTER TABLE XXMIP.XXMIP_CANCEL_AR_INVOICES ADD (
  CONSTRAINT XXMIP_CANCEL_AR_INVOICES_PK
  PRIMARY KEY
  (TRANSACTION_ID)
  USING INDEX XXMIP.XXMIP_CANCEL_AR_INVOICES_PK
  ENABLE VALIDATE);
