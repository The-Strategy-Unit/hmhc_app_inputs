-- README
-- Stored Procedure to create dataset for hmhc_app_inputs
-- SP pulls data for a user-defined time period
-- data pulled from 'vw_opc_main_1045'

USE [NHSE_Sandbox_StrategyUnit];
GO

-- DROP PROCEDURE [dbo].[sp_get_opc_grps_1045];
-- GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
SET NOCOUNT ON;
GO

CREATE PROCEDURE [dbo].[sp_get_opc_grps_1045]
@StartDt DATE,
@EndDt DATE

AS

SELECT
	setting,
	yyyymm,
	lacd,
	sex,
	age,
	is_first,
	is_tele,
	is_surg,
	has_proc,
	COUNT(id) n
	
FROM
	[NHSE_Sandbox_StrategyUnit].[dbo].[vw_opc_main_1045]

WHERE
	appdt >= @StartDt
		AND appdt <= @EndDt

GROUP BY
	setting,
	yyyymm,
	lacd,
	sex,
	age,
	is_first,
	is_tele,
	is_surg,
	has_proc;

GO

USE [NHSE_Sandbox_StrategyUnit];
GO

SET NOCOUNT ON

DECLARE @StartDt DATE,
				@EndDt DATE;

SET @StartDt = '2022-01-01';
SET @EndDt = '2022-12-31';

EXEC [dbo].[sp_get_opc_grps_1045] @StartDt, @EndDt;

GO
