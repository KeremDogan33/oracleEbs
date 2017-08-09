CREATE TABLE XXMIP.INSR_LINES_ALL
(
  INSURANCE_LINE_ID        NUMBER,
  INSURANCE_HEADER_ID      NUMBER,
  DAMAGED_TYPE             NUMBER,
  DAMAGED                  VARCHAR2(4000 BYTE),
  BENEFICIARY_TYPE         NUMBER,
  BENEFICIARY              NUMBER,
  ESTIMATED_COST           NUMBER,
  INVOICED_BY_TYPE         NUMBER,
  INVOICED_BY              NUMBER,
  INVOICE_NUMBER           NUMBER,
  INVOICE_AMOUNT           NUMBER,
  HAS_RECOURSE             VARCHAR2(1 BYTE),
  RECOURSE_INVOICE_NUMBER  NUMBER,
  RECOURSE_INVOICE_AMOUNT  NUMBER,
  CONCLUSION               NUMBER,
  PAYMENT_STATUS           NUMBER,
  CASE_STATUS              NUMBER,
  NOTE                     VARCHAR2(4000 BYTE),
  CREATION_DATE            DATE,
  CREATED_BY               NUMBER(15),
  LAST_UPDATE_DATE         DATE                 NOT NULL,
  LAST_UPDATED_BY          NUMBER(15)           NOT NULL,
  LAST_UPDATE_LOGIN        NUMBER(15),
  RELATED_DEPARTMENT       NUMBER
)
TABLESPACE XXMIP
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;


CREATE INDEX XXMIP.HEADER_REX_IX ON XXMIP.INSR_LINES_ALL
(INSURANCE_HEADER_ID)
LOGGING
TABLESPACE XXMIP
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          40K
            NEXT             40K
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      50
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           );

CREATE UNIQUE INDEX XXMIP.INSR_LINES_ALL_PK ON XXMIP.INSR_LINES_ALL
(INSURANCE_LINE_ID)
LOGGING
TABLESPACE XXMIP
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           );

ALTER TABLE XXMIP.INSR_LINES_ALL ADD (
  CONSTRAINT INSR_LINES_ALL_PK
  PRIMARY KEY
  (INSURANCE_LINE_ID)
  USING INDEX XXMIP.INSR_LINES_ALL_PK
  ENABLE VALIDATE);