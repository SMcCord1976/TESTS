USE [spc_dba_utilities]
GO
/****** Object:  Table [dbo].[spc_spt_unit_of_measure]    Script Date: 8/15/2024 4:33:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[spc_spt_unit_of_measure](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[unUomCode] [nvarchar](8) NOT NULL,
	[description] [nvarchar](256) NULL,
	[symbol] [nvarchar](16) NULL,
	[label] [nvarchar](256) NOT NULL,
	[dataType] [nvarchar](16) NOT NULL,
	[isDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_UnitOfMeasure] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[spc_spt_unit_of_measure] ADD  DEFAULT ('Fresh meat') FOR [dataType]
GO
ALTER TABLE [dbo].[spc_spt_unit_of_measure] ADD  DEFAULT ((0)) FOR [isDeleted]
GO
ALTER TABLE [dbo].[spc_spt_unit_of_measure]  WITH CHECK ADD CHECK  (([dataType]='Enum' OR [dataType]='Boolean' OR [dataType]='Numeric-Float' OR [dataType]='Numeric-Int' OR [dataType]='Text'))
GO
ALTER TABLE [dbo].[spc_spt_unit_of_measure]  WITH CHECK ADD CHECK  (([dataType]='Enum' OR [dataType]='Boolean' OR [dataType]='Numeric-Float' OR [dataType]='Numeric-Int' OR [dataType]='Text'))
GO
ALTER TABLE [dbo].[spc_spt_unit_of_measure]  WITH CHECK ADD CHECK  (([dataType]='Enum' OR [dataType]='Boolean' OR [dataType]='Numeric-Float' OR [dataType]='Numeric-Int' OR [dataType]='Text'))
GO
ALTER TABLE [dbo].[spc_spt_unit_of_measure]  WITH CHECK ADD CHECK  (([dataType]='Enum' OR [dataType]='Boolean' OR [dataType]='Numeric-Float' OR [dataType]='Numeric-Int' OR [dataType]='Text'))
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'spc_spt_unit_of_measure', @level2type=N'COLUMN',@level2name=N'id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'UN UOM Code' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'spc_spt_unit_of_measure', @level2type=N'COLUMN',@level2name=N'unUomCode'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'spc_spt_unit_of_measure', @level2type=N'COLUMN',@level2name=N'description'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'UoM Symbol' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'spc_spt_unit_of_measure', @level2type=N'COLUMN',@level2name=N'symbol'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Label' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'spc_spt_unit_of_measure', @level2type=N'COLUMN',@level2name=N'label'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Value Data Type' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'spc_spt_unit_of_measure', @level2type=N'COLUMN',@level2name=N'dataType'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Soft delete flag' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'spc_spt_unit_of_measure', @level2type=N'COLUMN',@level2name=N'isDeleted'
GO
