CREATE TABLE XXMIP.XLS_GLOBAL_HEADER_INTERFACE
(
  HEADER_ID          NUMBER,
  RESP_ID            NUMBER,
  FUNCTION_PARAM     VARCHAR2(50 BYTE),
  FILE_NAME          VARCHAR2(150 BYTE),
  CREATION_DATE      DATE,
  CREATED_BY         NUMBER,
  LAST_UPDATE_DATE   DATE,
  LAST_UPDATED_BY    NUMBER,
  LAST_UPDATE_LOGIN  NUMBER,
  XLS_FILE           BLOB,
  IS_PROCESSED       VARCHAR2(1 BYTE),
  REQUEST_ID         NUMBER,
  IS_LOADED          VARCHAR2(1 BYTE),
  LOAD_REQUEST_ID    NUMBER
)
LOB (XLS_FILE) STORE AS BASICFILE (
  TABLESPACE  XXMIP
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  RETENTION
  NOCACHE
  LOGGING
      STORAGE    (
                  INITIAL          64K
                  NEXT             1M
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  FREELISTS        1
                  FREELIST GROUPS  1
                  BUFFER_POOL      DEFAULT
                 ))
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

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.HEADER_ID IS 'PK';

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.RESP_ID IS 'SORUMLULUK_ID';

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.FUNCTION_PARAM IS 'DOSYA_TIPI';

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.FILE_NAME IS 'DOSYA_ADI';

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.XLS_FILE IS 'DOSYA_BLOB';

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.IS_PROCESSED IS 'DOSYA ��LEND� B�LG�S�';

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.REQUEST_ID IS 'DOSYA ��LEME REQUEST ID';

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.IS_LOADED IS 'DOSYA AKTARIM B�LG�S�';

COMMENT ON COLUMN XXMIP.XLS_GLOBAL_HEADER_INTERFACE.LOAD_REQUEST_ID IS 'DOSYA AKTARIM REQUEST ID';


CREATE UNIQUE INDEX XXMIP.XLS_GLOBAL_HEADER_INTERFACE_PK ON XXMIP.XLS_GLOBAL_HEADER_INTERFACE
(HEADER_ID)
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

CREATE OR REPLACE PUBLIC SYNONYM XLS_GLOBAL_HEADER_INTERFACE FOR XXMIP.XLS_GLOBAL_HEADER_INTERFACE;


ALTER TABLE XXMIP.XLS_GLOBAL_HEADER_INTERFACE ADD (
  CONSTRAINT XLS_GLOBAL_HEADER_INTERFACE_PK
  PRIMARY KEY
  (HEADER_ID)
  USING INDEX XXMIP.XLS_GLOBAL_HEADER_INTERFACE_PK
  ENABLE VALIDATE);

ALTER TABLE XXMIP.XLS_GLOBAL_INTERFACE_LINES ADD (
  CONSTRAINT FK_HEADER 
  FOREIGN KEY (HEADER_ID) 
  REFERENCES XXMIP.XLS_GLOBAL_HEADER_INTERFACE (HEADER_ID)
  ON DELETE CASCADE);
