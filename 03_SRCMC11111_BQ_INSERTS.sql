DELETE FROM DB_AEDWD2.ETL_JOB_DTL WHERE UPPER(ETL_INTF_CD) = 'SRCMC11111';
INSERT INTO ${AEDW_DB}.ETL_JOB_DTL values
('SRCMC11111', 'P1', 'J1', CURRENT_DATE(), 'Check Sourcing Run Status', 'NA', 'U', 'W', '00_001_Src_Run_Check.ksh', 1.0, "ksh \${PROGDIR}/00_001_Src_Run_Check.ksh", 'N', 'N', '9999-12-31', CURRENT_DATETIME('America/New_York')),
('SRCMC11111', 'P1', 'J2', CURRENT_DATE(), 'Load Delta Tables', 'NA', 'U', 'W', '01_010_Update_Delta_Tables.sql', 2.0, "ksh \${PROGDIR}/exec_btq.ksh", 'N', 'N', '9999-12-31', CURRENT_DATETIME('America/New_York')),
('SRCMC11111', 'P1', 'J3', CURRENT_DATE(), 'Load Delta Tables', 'NA', 'U', 'W', '01_020_HPMC_CGP.sql', 2.0, "ksh \${PROGDIR}/exec_btq.ksh", 'N', 'N', '9999-12-31', CURRENT_DATETIME('America/New_York'));
INSERT INTO ${AEDW_DB}.ETL_JOB_DTL values
('SRCMC11111', 'P2', 'J1', CURRENT_DATE(), 'Load DB SRC Tables', 'NA', 'U', 'W', '02_010_Load_STG1_Tables_PART1.sql', 1.0, "ksh \${PROGDIR}/exec_btq.ksh", 'N', 'N', '9999-12-31', CURRENT_DATETIME('America/New_York')),
('SRCMC11111', 'P2', 'J2', CURRENT_DATE(), 'Load DB SRC Tables', 'NA', 'U', 'W', '02_010_Load_STG1_Tables_PART2.sql', 1.0, "ksh \${PROGDIR}/exec_btq.ksh", 'N', 'N', '9999-12-31', CURRENT_DATETIME('America/New_York')),
('SRCMC11111', 'P2', 'J3', CURRENT_DATE(), 'Load WRK_HLH_SK_CSTM Table', 'NA', 'U', 'W', '03_000_WRK_HLH_EVNT_LKUP_CSTM.sql', 2.0, "ksh \${PROGDIR}/exec_btq.ksh", 'N', 'N', '9999-12-31', CURRENT_DATETIME('America/New_York'))
INSERT INTO ${AEDW_DB}.ETL_JOB_DTL values
('SRCMC11111', 'P2', 'J4', CURRENT_DATE(), '03_005_WRK_HLH_EVNT_LKUP_PRTN', 'NA', 'U', 'D', '03_005_WRK_HLH_EVNT_LKUP_PRTN.ksh', 3.0, 'ksh \${PROGDIR}/03_005_WRK_HLH_EVNT_LKUP_PRTN.ksh', 'Y', 'N', '9999-12-31', CURRENT_DATETIME()),
('SRCMC11111', 'P2', 'J5', CURRENT_DATE(), 'Load WRK_ADDR_SK_LKUP_CSTM Table', 'NA', 'U', 'W', '02_020_WRK_ADDR_SK_LKUP_CSTM.sql', 2.0, "ksh \${PROGDIR}/exec_btq.ksh", 'N', 'N', '9999-12-31', CURRENT_TIMESTAMP()),
('SRCMC11111', 'P2', 'J6', CURRENT_DATE(), 'addr_lookup_load', 'NA', 'U', 'D', 'addr_lookup_load.ksh', 3.0, 'ksh \${PROGDIR}/addr_lookup_load.ksh', 'Y', 'N', '9999-12-31', CURRENT_DATETIME());

DELETE FROM ${AEDW_DB}.ETL_PCS_DTL WHERE UPPER(ETL_INTF_CD) = 'SRCMC11111';
INSERT INTO DB_AEDWD2.ETL_PCS_DTL values
('SRCMC11111', 'P1', CURRENT_DATE(), 'Load Delta Tables', 1.0, 'Y', '9999-12-31', CURRENT_DATETIME('America/New_York')),
('SRCMC11111', 'P2', CURRENT_DATE(), 'Load DB SRC Tables', 2.0, 'Y', '9999-12-31', CURRENT_DATETIME('America/New_York')),
('SRCMC11111', 'P3', CURRENT_DATE(), 'Load Master Claim , Master Claim Line & Master SK population ', 3.0, 'Y', '9999-12-31', CURRENT_DATETIME('America/New_York'))

INSERT INTO DB_AEDWD2.ETL_PCS_DTL values
('SRCMC11111', 'P4', CURRENT_DATETIME(), 'Load DB STG2 Tables, 4.0, 'Y', '9999-12-31', CURRENT_DATETIME('America/New_York')),
('SRCMC11111', 'P5', CURRENT_DATE(), 'Subrogation Inserts ', 5.0, 'Y', '9999-12-31', CURRENT_DATETIME('America/New_York')),
('SRCMC11111', 'P6', CURRENT_DATE(), 'RI Check ', 6.0, 'Y', '9999-12-31', CURRENT_DATETIME('America/New_York'));
