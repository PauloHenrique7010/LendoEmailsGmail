object PrincipalFrm: TPrincipalFrm
  Left = 0
  Top = 0
  Caption = 'LER E-MAIL'
  ClientHeight = 467
  ClientWidth = 884
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    884
    467)
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 8
    Top = 215
    Width = 868
    Height = 2
    Anchors = [akLeft, akRight, akBottom]
    ExplicitTop = 207
    ExplicitWidth = 992
  end
  object Label3: TLabel
    Left = 8
    Top = 42
    Width = 88
    Height = 16
    Caption = 'E-mail HTML'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
  end
  object Label1: TLabel
    Left = 8
    Top = 226
    Width = 152
    Height = 16
    Caption = 'Informa'#231#245'es Obtidas'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
  end
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Iniciar'
    TabOrder = 0
    OnClick = Button1Click
  end
  object mmTexto: TMemo
    Left = 8
    Top = 64
    Width = 868
    Height = 129
    Anchors = [akLeft, akTop, akRight]
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object mmRaspagem: TMemo
    Left = 8
    Top = 256
    Width = 868
    Height = 169
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object rdbRecorte: TRadioButton
    Left = 97
    Top = 12
    Width = 65
    Height = 17
    Caption = 'Recorte'
    Checked = True
    TabOrder = 3
    TabStop = True
    OnClick = rdbRecorteClick
  end
  object rdbAndamento: TRadioButton
    Left = 168
    Top = 12
    Width = 82
    Height = 17
    Caption = 'Andamento'
    TabOrder = 4
    OnClick = rdbAndamentoClick
  end
  object btnFechar: TBitBtn
    Left = 792
    Top = 434
    Width = 84
    Height = 25
    Action = actFechar
    Anchors = [akRight, akBottom]
    Caption = 'FECHAR(ESC)'
    TabOrder = 5
  end
  object btnVisualizarEmail: TBitBtn
    Left = 672
    Top = 434
    Width = 114
    Height = 25
    Action = actVisualizarEmail
    Anchors = [akRight, akBottom]
    Caption = 'VISUALIZAR E-MAIL'
    TabOrder = 6
  end
  object IMAP: TIdIMAP4
    SASLMechanisms = <>
    MilliSecsToWaitToClearBuffer = 10
    Left = 840
  end
  object IO_OpenSSL: TIdSSLIOHandlerSocketOpenSSL
    MaxLineAction = maException
    Port = 0
    DefaultPort = 0
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 816
  end
  object ActionManager1: TActionManager
    Left = 792
    StyleName = 'Platform Default'
    object actFechar: TAction
      Caption = 'FECHAR(ESC)'
      ShortCut = 27
      OnExecute = actFecharExecute
    end
    object actVisualizarEmail: TAction
      Caption = 'VISUALIZAR E-MAIL'
      OnExecute = actVisualizarEmailExecute
    end
  end
end
