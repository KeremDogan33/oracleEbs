CREATE TABLE XXMIP.XLS_GLOBAL_HEADER_MAPPING_USG
(
  HEADER_ID             NUMBER,
  "SCHEMA"              VARCHAR2(50 BYTE),
  TABLE_NAME            VARCHAR2(150 BYTE),
  XLS_COLUMN            VARCHAR2(150 BYTE),
  COLUMN_FIELD_NAME     VARCHAR2(150 BYTE),
  COLUMN_FIELD_TYPE     VARCHAR2(50 BYTE),
  CREATION_DATE         DATE,
  CREATED_BY            NUMBER,
  LAST_UPDATE_DATE      DATE,
  LAST_UPDATED_BY       NUMBER,
  LAST_UPDATE_LOGIN     NUMBER,
  RECORD_ID             NUMBER,
  XLS_COLUMN_USER_NAME  VARCHAR2(150 BYTE),
  REQUIRED              VARCHAR2(1 BYTE)
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


CREATE UNIQUE INDEX XXMIP.XLS_GLOBAL_HEADER_MAPPING_U_PK ON XXMIP.XLS_GLOBAL_HEADER_MAPPING_USG
(HEADER_ID, RECORD_ID)
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

CREATE OR REPLACE SYNONYM APPS.XLS_GLOBAL_HEADER_MAPPING_USG FOR XXMIP.XLS_GLOBAL_HEADER_MAPPING_USG;


ALTER TABLE XXMIP.XLS_GLOBAL_HEADER_MAPPING_USG ADD (
  CONSTRAINT XLS_GLOBAL_HEADER_MAPPING_U_PK
  PRIMARY KEY
  (HEADER_ID, RECORD_ID)
  USING INDEX XXMIP.XLS_GLOBAL_HEADER_MAPPING_U_PK
  ENABLE VALIDATE);
