CREATE TABLE XXMIP.INSR_HEADERS_ALL
(
  INSURANCE_HEADER_ID    NUMBER,
  INSURANCE_FILE_NUMBER  VARCHAR2(10 BYTE),
  INSURANCE_TYPE         VARCHAR2(15 BYTE),
  FILE_NUMBER            VARCHAR2(10 BYTE),
  DAMAGED_DATE           DATE,
  DAMAGED_BY             NUMBER,
  ACCIDENT_SITE          NUMBER,
  RESPONSIBLE_OF_DAMAGE  VARCHAR2(255 BYTE),
  EXPLANATION            VARCHAR2(4000 BYTE),
  NOTE                   VARCHAR2(4000 BYTE),
  CREATION_DATE          DATE,
  CREATED_BY             NUMBER(15),
  LAST_UPDATE_DATE       DATE                   NOT NULL,
  LAST_UPDATED_BY        NUMBER(15)             NOT NULL,
  LAST_UPDATE_LOGIN      NUMBER(15),
  CASE_STATUS            NUMBER
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


CREATE UNIQUE INDEX XXMIP.INSR_HEADERS_ALL_PK ON XXMIP.INSR_HEADERS_ALL
(INSURANCE_HEADER_ID)
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

CREATE OR REPLACE SYNONYM APPS.XXMIP_INSR_HEADERS_ALL FOR XXMIP.INSR_HEADERS_ALL;


ALTER TABLE XXMIP.INSR_HEADERS_ALL ADD (
  CONSTRAINT INSR_HEADERS_ALL_PK
  PRIMARY KEY
  (INSURANCE_HEADER_ID)
  USING INDEX XXMIP.INSR_HEADERS_ALL_PK
  ENABLE VALIDATE);
