unit PrincipalForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IdText,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient,
  IdPOP3, Vcl.StdCtrls, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL, IdServerIOHandler, IdMailBox, IdMessage, IdIMAP4, System.NetEncoding,
  Vcl.Buttons, IdMessageCoder, IdMessageCoderMIME, Data.DB, Datasnap.DBClient,
  Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls, Vcl.PlatformDefaultStyleActnCtrls,
  System.Actions, Vcl.ActnList, Vcl.ActnMan, ShellAPI;

type
  TPrincipalFrm = class(TForm)
    Button1: TButton;
    mmTexto: TMemo;
    IMAP: TIdIMAP4;
    IO_OpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    Shape1: TShape;
    Label3: TLabel;
    Label1: TLabel;
    mmRaspagem: TMemo;
    rdbRecorte: TRadioButton;
    rdbAndamento: TRadioButton;
    ActionManager1: TActionManager;
    btnFechar: TBitBtn;
    actFechar: TAction;
    btnVisualizarEmail: TBitBtn;
    actVisualizarEmail: TAction;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure rdbRecorteClick(Sender: TObject);
    procedure rdbAndamentoClick(Sender: TObject);
    procedure actFecharExecute(Sender: TObject);
    procedure actVisualizarEmailExecute(Sender: TObject);
  private
    caminhoEArquivo : string;
    lCodigo, lCaracter : TStringlist;
    procedure lerEmailRecorte;
    procedure lerEmailRecorteHTML;
    procedure lerEmailAndamento;
    procedure lerEmailAndamentoHTML;
    procedure lerEmailAndamentoHTML2;
    function conteudoTag(texto,tagAbre, tagFecha : string):string;
    function removerTag(texto, inicioTag, fimTag: string):string;
  public
    { Public declarations }
  end;

var
  PrincipalFrm: TPrincipalFrm;

implementation

{$R *.dfm}

procedure TPrincipalFrm.actFecharExecute(Sender: TObject);
begin
  Close;
end;

procedure TPrincipalFrm.actVisualizarEmailExecute(Sender: TObject);
begin
  if (fileExists(caminhoEArquivo)) then
    ShellExecute(Application.Handle, nil,PCHAR(caminhoEArquivo), nil, nil, SW_SHOWNORMAL)
  else
    ShowMessage('Arquivo não encontrado, não é possível visualizar e-mail');
end;

procedure TPrincipalFrm.Button1Click(Sender: TObject);
var
  lMsg: TIdMessage;
  rec: array of TIdIMAP4SearchRec;
  contMsg, i: Integer;
  codEmail : integer;
  assuntoEmail : string;
begin
  with IO_OpenSSL do
  begin
    Destination := 'imap.gmail.com:993';
    Host := 'imap.gmail.com';
    Port := 995;
    SSLOptions.Method := sslvSSLv23;
    SSLOptions.Mode := sslmClient;
  end;

  with IMAP do
  begin
    IOHandler := IO_OpenSSL;
    Host := 'imap.gmail.com'; { Endereço do servidor }
    Username := 'email@gmail.com';
    UseTLS := utUseImplicitTLS;
    Password := 'senha';
    Port := 993; { Porta que o servidor está ouvindo }
    IMAP.Connect();
  end;

  if (IMAP.Connected) then
  begin
    IMAP.SelectMailBox('INBOX');
    SetLength(rec, 2);
    //caso queira buscar pelo dia e os que nao foram vistos
    //rec[1].SearchKey := skUnseen;
    rec[0].SearchKey := skSentOn; //enviado na data..

    rec[0].Date := StrToDate('09/12/2020');
    if (rdbAndamento.Checked) then
      rec[0].Date := StrToDate('14/12/2020');

    if not IMAP.SearchMailBox(rec) then
      raise Exception.Create('Erro na pesquisa da caixa postal');

    contMsg := Length(IMAP.MailBox.SearchResult);
    for i := 0 to Pred(contMsg) do
    begin
      lMsg := TIdMessage.Create(nil);
      lMsg.Encoding := mePlainText;

      //pegando do email mais antigo para o primeiro
      //codEmail := imap.MailBox.SearchResult[i];

      //to pegando o email mais recente para o mais antigo
      codEmail := imap.MailBox.SearchResult[contmsg-(i+1)];

      { *** recupera o email completo*** }
      imap.Retrieve(codEmail, lMsg);
      assuntoEmail := LowerCase(lMsg.Subject);

      //ORIGINAL
{      if MsgObject.MessageParts.TextPartCount > 0 then
                begin
                  for PartIndex := 0 to MsgObject.MessageParts.Count - 1 do
                    if MsgObject.MessageParts[PartIndex] is TIdText then
                      S := S + TIdText(MsgObject.MessageParts[PartIndex]).Body.Text;
                  BodyTexts.Add(S);
                end
                else
                  BodyTexts.Add(MsgObject.Body.Text);}


      //pega o html do email
      mmTexto.Lines.Text := (TIdText(lmsg.MessageParts[1]).Body.Text);
      mmTexto.Lines.SaveToFile(caminhoEArquivo,TEncoding.UTF8); //é salvo o arquivo caso queira ver o email

      mmRaspagem.Clear;

      if (Pos('recorte digital',assuntoEmail) > 0) then
        lerEmailRecorteHTML
      else if (Pos('andamento processual',assuntoEmail) > 0) then
        lerEmailAndamentoHTML2;
      break;

      //Marca como nao visto
      //IMAP.StoreFlags([codEmail],sdReplace,lMsg.Flags - [mfSeen]);
    end;
    IMAP.Disconnect();
  end;
end;

function TPrincipalFrm.conteudoTag(texto, tagAbre, tagFecha: string): string;
var
  textoAuxiliar : string;
  posAuxiliar : integer;
begin
  if (Pos('>',tagAbre) = 0) then
  begin
    textoAuxiliar := texto;
    posAuxiliar := pos('>',textoAuxiliar);
    tagAbre:= Copy(textoAuxiliar,0,posAuxiliar);
  end;

  //se encontrar a tag, faz a raspagem
  if (pos(tagAbre, texto) > 0) then
  begin
    texto := copy(texto, pos(tagAbre,texto)+tagAbre.Length);//para nao aparecer na string
    texto := copy(texto, 0, pos(tagFecha,texto)-1);
    texto := StringReplace(texto,sLineBreak,'',[rfReplaceAll]);
  end;
  result := texto;
end;


procedure TPrincipalFrm.FormCreate(Sender: TObject);
begin
  caminhoEArquivo := ExtractFilePath(Application.ExeName)+'email.html';
end;

procedure TPrincipalFrm.lerEmailAndamento;
var
  posicao : integer;
  texto : string;
  textoAtual: string;
  posAtual: integer;
  posProximo : integer;

  textoRepeticao : string;

  posAuxiliar : integer;
  textoAuxiliar : string;
begin
  texto := mmTexto.Lines.Text;
  //corta a string até a parte do html para ficar menor..
  posicao := Pos('<html',texto);
  texto := Copy(texto,0,posicao);
  mmTexto.Lines.Text := Texto;


  //pega a apartir
  posicao := Pos('O sistema PUSH está disponibilizando ',texto);
  texto := Copy(texto,posicao);


  posicao := Pos('abaixo:',texto);
  texto := Copy(texto,posicao+7);
  textoRepeticao := sLineBreak+sLineBreak+sLineBreak+sLineBreak+sLineBreak;
  while (posicao > 0) do
  begin
    //tipo do andamento
    posAtual := 0;
    posProximo := Pos('Assunto:',texto)-1;
    textoAtual:= Copy(texto,0,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    //REMOVE O HTML QUE ESTA NO MEIO DA STRING
    posAuxiliar := pos('<',textoAtual);
    textoAuxiliar := Copy(textoAtual,0,posAuxiliar-1);
    posAuxiliar := pos('>',textoAtual)+1;
    textoAtual := textoAuxiliar + copy(textoAtual,posAuxiliar);

    showMessage(textoAtual);

    texto := Copy(texto,posProximo);

    posAtual:= Pos('Assunto:',texto);
    posProximo := Pos('Advogados:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);

    showMessage(textoAtual);

    texto := Copy(texto,posProximo);

    posAtual:= Pos('Advogados:',texto);
    posProximo := Pos('Novas Movimentações',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);

    showMessage(textoAtual);

    texto := Copy(texto,posProximo);

    //Movimentacoes
    posAtual:= Pos('Novas Movimentações',texto);
    posProximo := Pos(textoRepeticao,texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);

    showMessage(textoAtual);

    posicao := pos(textoRepeticao,texto);
    texto := Copy(texto,posicao);
  end;
end;

procedure TPrincipalFrm.lerEmailAndamentoHTML;
var
  posicao : integer;
  texto : string;
  textoAtual: string;
  textoRepeticao : string;
  textoAuxiliar : string;

  OPLoop : boolean;
begin
  texto := mmTexto.Lines.Text;

  posicao := Pos('O sistema PUSH está disponibilizando ',texto);
  texto := Copy(texto,posicao);
  texto := StringReplace(texto,'<o:p>','',[rfReplaceAll]);
  texto := StringReplace(texto,'</o:p>','',[rfReplaceAll]);
  texto := StringReplace(texto,'<br>','',[rfReplaceAll]);
  texto := StringReplace(texto,'&nbsp;','',[rfReplaceAll]);


  posicao := Pos('<table',texto);
  texto := Copy(texto,posicao+1);
  while (posicao > 0) do
  begin
    mmRaspagem.Lines.Add('----------------------------------------------------------------------------------------------------------');
    textoRepeticao := texto;
    posicao := pos('<tr',textoRepeticao);
    textoRepeticao := Copy(textoRepeticao,posicao);

    textoAtual := textoRepeticao;
    textoAtual := conteudoTag(textoAtual,'<tr>','</tr>');
    textoAtual := conteudoTag(textoAtual,'<td','</td>');
    textoAtual := conteudoTag(textoAtual,'<p','</p>');

    textoAuxiliar := textoAtual;
    textoAuxiliar := conteudoTag(textoAuxiliar,'<a','</a>');
    textoAuxiliar := conteudoTag(textoAuxiliar,'<span','</span>');

    textoAtual := removerTag(textoAtual, '<a','</a>');
    textoAtual := textoAtual + textoAuxiliar;

    mmRaspagem.Lines.Add('Título...: '+textoAtual);

    // **  AVISO  **
    //AS VEZES APARECE UM CAMPO CHAMADO CLASSE
      textoAtual := textoRepeticao;
      textoAtual := copy(textoAtual,3);
      posicao := pos('<tr',textoAtual);
      textoAtual := Copy(textoAtual,posicao);

      //Palavra: Classe
      textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
      textoAtual := conteudoTag(textoAtual,'<td','</td>');
      textoAtual := conteudoTag(textoAtual,'<p','</p>');
      textoAtual := conteudoTag(textoAtual,'<strong','</strong>');

      if (textoAtual = 'Classe:') then
      begin
        //passa para o proximo tr dentro do table
        textoRepeticao := copy(textoRepeticao,3);
        posicao := pos('<tr',textoRepeticao);
        textoRepeticao := Copy(textoRepeticao,posicao);

        textoAtual := textoRepeticao;
        textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
        //passo para o segundo td
        textoAtual := Copy(textoAtual,Pos('<td',textoAtual,2));
        textoAtual := conteudoTag(textoAtual,'<td','</td>');
        textoAtual := conteudoTag(textoAtual,'<p','</p>');
        mmRaspagem.Lines.Add('Classe...: '+textoAtual);

        //se for classe, o que fazer com ela..

      end;
    // **  AVISO  **
    //AS VEZES APARECE UM CAMPO CHAMADO CLASSE


    //passa para o proximo tr dentro do table
    textoRepeticao := copy(textoRepeticao,3);
    posicao := pos('<tr',textoRepeticao);
    textoRepeticao := Copy(textoRepeticao,posicao);

    //Pega a palavra "Assunto"
    textoAtual := textoRepeticao;
    textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
    textoAtual := conteudoTag(textoAtual,'<td','</td>');
    textoAtual := conteudoTag(textoAtual,'<p','</p>');
    textoAtual := conteudoTag(textoAtual,'<strong','</strong>');


    //um tr contem dois td, o primeiro é a palavra e o segundo o conteudo
    textoAtual := textoRepeticao;
    textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
    //passo para o segundo td
    textoAtual := Copy(textoAtual,Pos('<td',textoAtual,2));
    textoAtual := conteudoTag(textoAtual,'<td','</td>');
    textoAtual := conteudoTag(textoAtual,'<p','</p>');
    mmRaspagem.Lines.Add('Assunto..: '+textoAtual);

    //pula proxima linha
    textoRepeticao := copy(textoRepeticao,3);
    posicao := pos('<tr',textoRepeticao);
    textoRepeticao := Copy(textoRepeticao,posicao);


    mmRaspagem.Lines.Add('Advogados:');
    //pega os advogados do andamento..
    OPLoop := true;
    while (OPLoop) do
    begin
      //Pega a palavra "Advogados"
      textoAtual := textoRepeticao;
      textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
      textoAtual := conteudoTag(textoAtual,'<td','</td>');
      textoAtual := conteudoTag(textoAtual,'<p','</p>');
      textoAtual := conteudoTag(textoAtual,'<strong','</strong>');


      //se aparecer Novas Movimentacoes, é pq acabou os advogados..
      if (textoAtual = 'Novas Movimentações') then
        OPLoop := false
      else  //se possuir mais de um advogado, pega eles..
      begin
        //passo para o outro tr onde realmente esta o advogado
        textoAtual := textoRepeticao;
        textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
        //passo para o segundo td
        textoAtual := Copy(textoAtual,Pos('<td',textoAtual,2));
        textoAtual := conteudoTag(textoAtual,'<td','</td>');
        textoAtual := conteudoTag(textoAtual,'<p','</p>');
        mmRaspagem.Lines.Add('- '+textoAtual);
      end;

      //pula proxima linha
      textoRepeticao := copy(textoRepeticao,3);
      posicao := pos('<tr',textoRepeticao);
      textoRepeticao := Copy(textoRepeticao,posicao);
    end;

    mmRaspagem.Lines.Add('');
    mmRaspagem.Lines.Add('Movimentações');
    //Movimentacoes
    OPLoop := true;
    while (OPLoop) do
    begin
      //Data movimentacao
      textoAtual := textoRepeticao;
      textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
      textoAtual := conteudoTag(textoAtual,'<td','</td>');
      textoAtual := conteudoTag(textoAtual,'<p','</p>');
      textoAtual := conteudoTag(textoAtual,'<strong','</strong>');
      mmRaspagem.Lines.Add('');
      mmRaspagem.Lines.Add(textoAtual);

      //Texto movimentacao para o outro tr onde realmente esta o advogado
      textoAtual := textoRepeticao;
      textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
      //passo para o segundo td
      textoAtual := Copy(textoAtual,Pos('<td',textoAtual,2));
      textoAtual := conteudoTag(textoAtual,'<td','</td>');
      textoAtual := conteudoTag(textoAtual,'<p','</p>');
      mmRaspagem.Lines.Add(textoAtual);


      //DAQUI PARA BAIXO VERIFICA SE CHEGOU NO FINAL DAS MOVIMENTAÇÕES

      //Como é feito, pulo duas linhas, se na segunda linha ele encontrar 'assunto, classe ou advogado:',
      //é pq na primeira linha ele saiu das movimentacoes

      //pula proxima linha
      textoAtual := textoRepeticao;
      textoAtual := copy(textoAtual,3);
      posicao := pos('<tr',textoAtual);
      textoAtual := Copy(textoAtual,posicao);

      textoAtual := copy(textoAtual,3);
      posicao := pos('<tr',textoAtual);
      textoAtual := Copy(textoAtual,posicao);

      textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
      textoAtual := conteudoTag(textoAtual,'<td','</td>');
      textoAtual := conteudoTag(textoAtual,'<p','</p>');
      textoAtual := conteudoTag(textoAtual,'<strong','</strong>');

      //chegou no final das movimentacoes
      if ((textoAtual = 'Assunto:') OR
          (textoAtual = 'Advogados:') or
          (textoAtual = 'Classe:') or
          (textoAtual = '')//para o ultimo registro
          ) then
        opLoop := false
      else
      begin

        //pulo uma linha
        textoRepeticao := copy(textoRepeticao,3);
        posicao := pos('<tr',textoRepeticao);
        textoRepeticao := Copy(textoRepeticao,posicao);
        //pulo uma linha
        textoRepeticao := copy(textoRepeticao,3);
        posicao := pos('<tr',textoRepeticao);
        textoRepeticao := Copy(textoRepeticao,posicao);
      end
    end;

    //procura a proxima tabela
    posicao := Pos('<table',texto);
    texto := Copy(texto,posicao+1);

    mmRaspagem.Lines.Add('----------------------------------------------------------------------------------------------------------');
    mmRaspagem.Lines.Add('');
  end;
end;

procedure TPrincipalFrm.lerEmailAndamentoHTML2;
function pegarTituloMovimentacao(texto:string):string;
var
  textoAuxiliar, textoAtual : string;
begin
  textoAtual := texto;
  textoAtual := conteudoTag(textoAtual,'<tr>','</tr>');
  textoAtual := conteudoTag(textoAtual,'<td','</td>');
  textoAtual := conteudoTag(textoAtual,'<p','</p>');

  textoAuxiliar := textoAtual;
  textoAuxiliar := conteudoTag(textoAuxiliar,'<a','</a>');
  textoAuxiliar := conteudoTag(textoAuxiliar,'<span','</span>');

  textoAtual := removerTag(textoAtual, '<a','</a>');
  textoAtual := textoAtual + textoAuxiliar;

  result := textoAtual;
end;
function pegarLinkTituloMovimentacao(texto:string):string;
var
  textoAuxiliar : string;
  textoBusca : string;
begin
  texto := conteudoTag(texto,'<tr>','</tr>');
  texto := conteudoTag(texto,'<td','</td>');
  texto := conteudoTag(texto,'<p','</p>');

  textoBusca := 'href="';

  //encontro o inicio do link
  texto := copy(texto,pos(textoBusca,texto)+textoBusca.Length);

  //copio tudo que esta apartir do " do href até a proxima aspas
  texto := copy(texto, 0, pos('"',texto)-1);

  result := texto;
end;
function proximoTR(texto:string):string;
var
  posicao : integer;
begin
  //Avanço um pouco para procruar o proximo tr
  texto := Copy(texto, 3);
  posicao := pos('<tr', texto);
  texto := copy(texto, posicao);
  result := texto;
end;
function pegarConteudoTR(texto:string):string;
var
  posicao : integer;
begin
  texto := conteudoTag(texto,'<tr','</tr>');
  posicao := Pos('<td',texto,2);
  texto := copy(texto,posicao);
  texto := conteudoTag(texto,'<td','</td>');
  texto := conteudoTag(texto,'<p','</p>');

  texto := StringReplace(texto,'<b>','',[rfReplaceAll]);
  texto := StringReplace(texto,'</b>','',[rfReplaceAll]);

  result := texto;
end;
function pegarTituloTR(texto:string):string;
var
  posicao : integer;
begin
  texto := conteudoTag(texto,'<tr','</tr>');
  texto := conteudoTag(texto,'<td','</td>');
  texto := conteudoTag(texto,'<p','</p>');
  texto := conteudoTag(texto,'<strong>','</strong>');

  texto := StringReplace(texto,'<b>','',[rfReplaceAll]);
  texto := StringReplace(texto,'</b>','',[rfReplaceAll]);

  result := texto;
end;
procedure pegarMovimentacoes(texto:string;var lLista:TStringlist);
var
  textoAtual : string;
  OPTemMovimentacao : boolean;
begin
  lLista.Clear;
  OPTemMovimentacao := true;
  while (OPTemMovimentacao) do
  begin
    lLista.Add(''); //pula linha
    //pega a data
    textoAtual := texto;
    textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
    textoAtual := conteudoTag(textoAtual,'<td','</td>');
    textoAtual := conteudoTag(textoAtual,'<p','</p>');
    lLista.Add(textoAtual);

    textoAtual := texto;
    textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
    textoAtual := Copy(textoAtual, pos('<td',textoAtual)+3);
    textoAtual := Copy(textoAtual, pos('<td', textoAtual));
    textoAtual := conteudoTag(textoAtual,'<td','</td>');
    textoAtual := conteudoTag(textoAtual,'<p','</p>');
    lLista.Add(textoAtual);

    //QUANDO É MAIS DE UMA MOVIMENTAÇÃO, PARA SEPARAR UMA DE OUTRA, TEM DOIS ENTER(TR)
    texto := proximoTR(texto); //proxima linha;
    texto := proximoTR(texto); //proxima linha;

    //VERIFICO SE ACABOU AS MOVIMENTAÇÕES
    textoAtual := texto;
    //textoAtual := proximoTR(textoAtual);
    textoAtual := pegarTituloTR(textoAtual);
    if ((textoAtual = 'Assunto:') or
        (textoAtual = 'Classe:') or
        (textoAtual = 'Advogados:') or
        (textoAtual = '')) then //'' -> para o ultimo registro
      OPTemMovimentacao := false;
  end;
end;
procedure pegarAdvogadosTR(texto:string;var lLista:TStringlist);
var
  textoAtual : string;
  OPTemAdvogado : boolean;
begin
  lLista.Clear;
  OPTemAdvogado := true;
  while (OPTemAdvogado) do
  begin
    textoAtual := texto;
    textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
    textoAtual := Copy(textoAtual, pos('<td',textoAtual)+3);
    textoAtual := Copy(textoAtual, pos('<td', textoAtual));
    textoAtual := conteudoTag(textoAtual,'<td','</td>');
    textoAtual := conteudoTag(textoAtual,'<p','</p>');
    lLista.Add(textoAtual);

    texto := proximoTR(texto);//prox linha

    //Verifico se é o ultimo
    textoAtual := texto;
    textoAtual := conteudoTag(textoAtual,'<tr','</tr>');
    textoAtual := conteudoTag(textoAtual,'<td','</td>');
    textoAtual := conteudoTag(textoAtual,'<p','</p>');
    if (textoAtual = 'Novas Movimentações') then
      OPTemAdvogado := false;
  end;
end;
function pularTRs(texto:string;qtdePular:integer):string;
var
  posicao : integer;
  I: Integer;
begin
  for I := 1 to qtdePular-1 do
  begin
    texto := Copy(texto, 3);//comeca a partir do 3 caracter
    posicao := Pos('<tr',texto);  //acha o proximo tr
    texto := Copy(texto, posicao); //vai pro proximo tr
  end;
  result := texto;
end;
//FUNÇÃO PRINCIPAL DAQUI PARA BAIXO
var
  texto : string;
  textoAtual: string;
  posicao : integer;

  llista : TStringlist;
  I: Integer;
begin
  texto := mmTexto.Lines.Text;

  posicao := Pos('O sistema PUSH está disponibilizando ',texto);
  texto := Copy(texto,posicao);
  texto := StringReplace(texto,'<o:p>','',[rfReplaceAll]);
  texto := StringReplace(texto,'</o:p>','',[rfReplaceAll]);
  texto := StringReplace(texto,'<br>','',[rfReplaceAll]);
  texto := StringReplace(texto,'&nbsp;','',[rfReplaceAll]);


  lLista := TStringlist.Create;
  posicao := Pos('<table',texto);
  texto := Copy(texto,posicao+1);
  while (posicao > 0) do
  begin
    mmRaspagem.Lines.Add('----------------------------------------------------------------------------------------------------------');
    //Titulo
    texto := proximoTR(texto);
    textoAtual := texto;
    textoAtual := pegarTituloMovimentacao(textoAtual);
    mmRaspagem.Lines.Add('Título...: '+textoAtual);
    //Pegar o link do titulo
    textoAtual := texto;
    textoAtual := pegarLinkTituloMovimentacao(texto);
    mmRaspagem.Lines.Add('Acesso...: '+textoAtual);


    //AVISO, ALGUNS REGISTROS TEM UM CAMPO CHAMADO CLASSE...
    //FAÇO UM IF VERIFICADO SE TEM.. SE TIVER EU IMPRIMO..
      //Classe
      textoAtual := texto;
      textoAtual := proximoTR(textoAtual);
      textoAtual := pegarTituloTR(textoAtual);  //palavra classe
      if (textoAtual = 'Classe:') then
      begin
        textoAtual := texto;
        textoAtual := proximoTR(textoAtual);
        textoAtual := pegarConteudoTR(textoAtual); // conteudo da classe
        mmRaspagem.Lines.Add('Classe...: '+textoAtual);
        texto := proximoTR(texto);
      end;


    //ASSUNTO
    texto := proximoTR(texto);
    textoAtual := texto;
    textoAtual := pegarTituloTR(textoAtual);  //palavra assunto

    textoAtual := texto;
    textoAtual := pegarConteudoTR(textoAtual); // conteudo do assunto
    mmRaspagem.Lines.Add('Assunto..: '+textoAtual);

    //ADVOGADO
    texto := proximoTR(texto);
    textoAtual := texto;
    textoAtual := pegarTituloTR(textoAtual);  //palavra

    mmRaspagem.Lines.Add('Advogados:');
    textoAtual := texto;
    pegarAdvogadosTR(textoAtual,lLista); // conteudo
    for I := 0 to lLista.Count-1 do
      mmRaspagem.Lines.Add(' - '+lLista.Strings[i]);

    texto := pularTRs(texto,lLista.Count);

    //NOVAS MOVIMENTAÇÕES
    texto := proximoTR(texto);
    textoAtual := texto;
    textoAtual := pegarTituloTR(textoAtual);  //palavra

    texto := proximoTR(texto);
    textoAtual := texto;
    pegarMovimentacoes(textoAtual, lLista); // conteudo

    mmRaspagem.Lines.Add('');
    mmRaspagem.Lines.Add('Movimentações:');
    for I := 0 to lLista.Count-1 do
    begin
      mmRaspagem.Lines.Add(lLista.Strings[i]);
    end;


    posicao := Pos('<table',texto);
    texto := Copy(texto,posicao+1);
    mmRaspagem.Lines.Add('----------------------------------------------------------------------------------------------------------');
    mmRaspagem.Lines.Add('');
  end;
  lLista.Free;
end;

procedure TPrincipalFrm.lerEmailRecorte;
var
  posicao : integer;
  texto : string;
  textoAtual: string;
  posAtual: integer;
  posProximo : integer;

  textoRepeticao : string;
begin
  texto := mmTexto.Lines.Text;
  posicao := Pos('<html',texto);
  texto := Copy(texto,0,posicao);
  mmTexto.Lines.Text := Texto;


  //pega a apartir
  posicao := Pos('Recorte Digital - OAB',texto);
  texto := Copy(texto,posicao);

  posAtual:= Pos('Advogado(a)',texto);
  posProximo := Pos('Número da OAB',texto);
  textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
  textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
  textoAtual := Copy(textoAtual,12);
//  edtAdvogado.Text := textoAtual;

  posAtual:= Pos('Número da OAB',texto);
  posProximo := Pos('Data processamento/pesquisa',texto);
  textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
  textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
  textoAtual := Copy(textoAtual,15);
//  edtOAB.Text := textoAtual;

  posAtual:= Pos('Data processamento/pesquisa',texto);
  posProximo := Pos('Atalhos:',texto);
  textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
  textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);


  //pegar os lançamentos
  posicao := Pos('Envio sem a pesquisa das publicações vindouras do Tribunal',texto);
  texto := Copy(texto,posicao, texto.Length);
  textoRepeticao := 'Data de Disponibilização:';
  posicao := pos(textoRepeticao,texto);
  texto := Copy(texto,posicao);
  while (posicao > 0) do
  begin


    //pega a Data de disponibilização
    posAtual:= Pos('Data de Disponibilização:',texto);
    posProximo := Pos('Data de Publicação:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    textoAtual := Copy(textoAtual,pos(':',textoAtual)+1);
//    cdsRegistros.FieldByName('dt_disponibilizacao').AsDateTime := StrToDateDef(textoAtual,0);


    texto := Copy(texto,posProximo);

    //pega a Data de publicacao
    posAtual:= Pos('Data de Publicação:',texto);
    posProximo := Pos('Jornal:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    textoAtual := Copy(textoAtual,pos(':',textoAtual)+1);
//    cdsRegistros.FieldByName('dt_publicacao').AsDateTime := StrToDateDef(textoAtual,0);

    texto := Copy(texto,posProximo);

    //pega o jornal
    posAtual:= Pos('Jornal:',texto);
    posProximo := Pos('Página:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    textoAtual := Copy(textoAtual,pos(':',textoAtual)+1);
//    cdsRegistros.FieldByName('jornal').AsString:= textoAtual;

    texto := Copy(texto,posProximo);

    //pega a pagina
    posAtual:= Pos('Página:',texto);
    posProximo := Pos('Caderno:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    textoAtual := Copy(textoAtual,pos(':',textoAtual)+1);
//    cdsRegistros.FieldByName('pagina').AsString:= textoAtual;

    texto := Copy(texto,posProximo);

    //pega o caderno
    posAtual:= Pos('Caderno:',texto);
    posProximo := Pos('Local:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    textoAtual := Copy(textoAtual,pos(':',textoAtual)+1);
//    cdsRegistros.FieldByName('caderno').AsString:= textoAtual;

    texto := Copy(texto,posProximo);

    //pega o Local
    posAtual:= Pos('Local:',texto);
    posProximo := Pos('Vara:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    textoAtual := Copy(textoAtual,pos(':',textoAtual)+1);
//    cdsRegistros.FieldByName('local').AsString:= textoAtual;

    texto := Copy(texto,posProximo);

    //pega a vara
    posAtual:= Pos('Vara:',texto);
    posProximo := Pos('Publicação:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    textoAtual := Copy(textoAtual,pos(':',textoAtual)+1);
//    cdsRegistros.FieldByName('vara').AsString:= textoAtual;

    texto := Copy(texto,posProximo);


    //pega a publicação
    posAtual:= Pos('Publicação:',texto);
    posProximo := Pos('Página:',texto);
    textoAtual:= Copy(texto,posAtual,posProximo-posAtual);
    textoAtual:= StringReplace(textoAtual,sLineBreak,'',[rfReplaceAll]);
    textoAtual := Copy(textoAtual,pos(':',textoAtual)+1);
//    cdsRegistros.FieldByName('publicacao').AsString:= textoAtual;

    texto := Copy(texto,posProximo);

    posicao := pos(textoRepeticao,texto);
    texto := Copy(texto,posicao);
//    cdsRegistros.Post;
  end;
end;

procedure TPrincipalFrm.lerEmailRecorteHTML;
function pegarLinkPublicacao(texto:string):string;
var
  textoBusca : string;
begin
  texto := conteudoTag(texto,'<tr>','</tr>');
  texto := conteudoTag(texto,'<td','</td>');
  texto := conteudoTag(texto,'<div','</div>');
  texto := conteudoTag(texto,'<p','</p>');
  texto := conteudoTag(texto,'<span','</span>');

  textoBusca := 'href="';

  //pego o texto a partir do link -> href=" -> www..
  texto := Copy(texto,pos(textoBusca,texto)+textoBusca.Length);

  //pego ate a primiera aspas(onde fecha o href)
  texto := Copy(texto,0,pos('"',texto)-1);
  result := texto;
end;
function proximoTR(texto:string):string;
var
  posicao : integer;
begin
  //Avanço um pouco para procruar o proximo tr
  texto := Copy(texto, 3);
  posicao := pos('<tr', texto);
  texto := copy(texto, posicao);
  result := texto;
end;
function pegarConteudoTR(texto:string):string;
var
  posicao : integer;
begin
  //Pegando Jornal
  texto := conteudoTag(texto,'<tr>','</tr>');
  texto := conteudoTag(texto,'<td','</td>');
  texto := conteudoTag(texto,'<p','</p>');

  posicao := pos('<span',texto)+4;
  texto := copy(texto,posicao);

  //pego o segundo span
  posicao := pos('<span',texto);
  texto := copy(texto,posicao);
  texto := conteudoTag(texto,'<span','</span>');

  texto := StringReplace(texto,'<b>','',[rfReplaceAll]);
  texto := StringReplace(texto,'</b>','',[rfReplaceAll]);

  result := texto;
end;
function pegarConteudoTRVara(texto:string):string;
var
  posicao : integer;
begin
  texto:= conteudoTag(texto,'<tr>','</tr>');
  texto := conteudoTag(texto,'<td','</td>');
  texto := conteudoTag(texto,'<div','</div>');
  texto := conteudoTag(texto,'<p','</p>');

  posicao := Pos('<span',texto);
  texto := copy(texto,posicao+3); //pega o primeiro span mais 3 //para pegar o 2 span

  posicao := Pos('<span',texto);
  texto := copy(texto,posicao);
  texto := conteudoTag(texto,'<span','</span>');

  //por conta do conteudo do local e o conteudo da vara estarem no msm tag
  //copio o texto a partir da tag <br>
  posicao := Pos('</b>',texto)+5;//para não pegar o "</b> "
  texto := copy(texto,posicao);
  result := texto;
end;
function pegarConteudoTRLocal(texto:string):string;
var
  posicao : integer;
begin
  texto:= conteudoTag(texto,'<tr>','</tr>');
  texto := conteudoTag(texto,'<td','</td>');
  texto := conteudoTag(texto,'<div','</div>');
  texto := conteudoTag(texto,'<p','</p>');

  posicao := Pos('<span',texto);
  texto := copy(texto,posicao+3); //pega o primeiro span mais 3 //para pegar o 2 span

  posicao := Pos('<span',texto);
  texto := copy(texto,posicao);
  texto := conteudoTag(texto,'<span','</span>');
  //por conta do conteudo do local e a palavra "vara" estarem no msm tag
  //copio o texto até a tag <br> que é onde acaba
  texto := copy(texto,0,pos('<b>',texto)-1);
  result := texto;
end;
var
  posicao : integer;
  texto : string;
  textoAtual: string;

  contador : integer;
begin
  texto := mmTexto.Lines.Text;

  posicao := Pos('Recorte Digital - OAB', texto);
  texto := Copy(texto,posicao+1);
  texto := StringReplace(texto,'<o:p>','',[rfReplaceAll]);
  texto := StringReplace(texto,'</o:p>','',[rfReplaceAll]);
  texto := StringReplace(texto,'<br>','',[rfReplaceAll]);
  texto := StringReplace(texto,'&nbsp;',' ',[rfReplaceAll]);

  texto := proximoTR(texto);

  //palavra advogado
  textoAtual := texto;
  textoAtual := conteudoTag(textoAtual,'<tr>','</tr>');
  textoAtual := conteudoTag(textoAtual,'<td','</td>');
  textoAtual := conteudoTag(textoAtual,'<p','</p>');
  textoAtual := conteudoTag(textoAtual,'<b>','</b>');
  textoAtual := conteudoTag(textoAtual,'<span','</span>');

  //conteudo advogado
  textoAtual := texto;
  textoAtual := conteudoTag(textoAtual,'<tr>','</tr>');
  textoAtual := Copy(textoAtual,pos('<td',textoAtual,2));

  textoAtual := conteudoTag(textoAtual,'<td','</td>');
  textoAtual := conteudoTag(textoAtual,'<p','</p>');
  textoAtual := conteudoTag(textoAtual,'<b>','</b>');
  textoAtual := conteudoTag(textoAtual,'<span','</span>');
  mmRaspagem.Lines.Add('Advogado..: '+textoAtual);

  texto := proximoTR(texto);

  //palavra "Numero da OAB"
  textoAtual := texto;
  textoAtual := conteudoTag(textoAtual,'<tr>','</tr>');
  textoAtual := conteudoTag(textoAtual,'<td','</td>');
  textoAtual := conteudoTag(textoAtual,'<p','</p>');
  textoAtual := conteudoTag(textoAtual,'<b>','</b>');
  textoAtual := conteudoTag(textoAtual,'<span','</span>');


  //conteudo OAB
  textoAtual := texto;
  textoAtual := conteudoTag(textoAtual,'<tr>','</tr>');
  textoAtual := Copy(textoAtual,pos('<td',textoAtual,2));

  textoAtual := conteudoTag(textoAtual,'<td','</td>');
  textoAtual := conteudoTag(textoAtual,'<p','</p>');
  textoAtual := conteudoTag(textoAtual,'<b>','</b>');
  textoAtual := conteudoTag(textoAtual,'<span','</span>');
  mmRaspagem.Lines.Add('Num OAB...: '+textoAtual);

  mmRaspagem.Lines.Add('');

  contador := 0;
  posicao := pos('Publicação: ', texto);
  texto := copy(texto, posicao+1);
  while (posicao > 0) do
  begin
    mmRaspagem.Lines.Add('----------------------------------------------------------------------------------------------------------');
    contador := contador + 1;

    mmRaspagem.Lines.Add('Publicação: '+IntToStr(contador));
    texto := proximoTR(texto);

    mmRaspagem.Lines.Add('Dt. Dispo.: '+Trim(pegarConteudoTR(texto)));
    texto := proximoTR(texto);

    mmRaspagem.Lines.Add('Dt. Publi.: '+Trim(pegarConteudoTR(texto)));
    texto := proximoTR(texto);

    mmRaspagem.Lines.Add('Jornal....: '+Trim(pegarConteudoTR(texto)));
    texto := proximoTR(texto);

    mmRaspagem.Lines.Add('Página....: '+Trim(pegarConteudoTR(texto)));
    texto := proximoTR(texto);

    mmRaspagem.Lines.Add('Caderno...: '+Trim(pegarConteudoTR(texto)));
    texto := proximoTR(texto);

    //AVISO -> POR CONTA DO "LOCAL" E A "VARA" ESTAREM NO MSM TR, TENHO QUE MONTAR
    //UM ALGORITIMO DIFERENTE, POR ISSO NÃO PULO LINHA ENTRE OS DOIS

    //AVISO - NOME DE FUNÇÃO DIFERENTE -> QUANDO MANUTENÇÃO, DAR ATENCAO
    mmRaspagem.Lines.Add('Local.....: '+Trim(pegarConteudoTRLocal(texto)));
    //AVISO - NOME DE FUNÇÃO DIFERENTE -> QUANDO MANUTENÇÃO, DAR ATENCAO
    mmRaspagem.Lines.Add('Vara......: '+Trim(pegarConteudoTRVara(texto)));
    texto := proximoTR(texto);

    mmRaspagem.Lines.Add('Publicação: '+Trim(pegarConteudoTR(texto)));
    texto := proximoTR(texto);

    //link do "Pagina: Ver a página" dps da publicação
    mmRaspagem.Lines.Add('Acesso....: '+pegarLinkPublicacao(texto));
    texto := proximoTR(texto);

    mmRaspagem.Lines.Add('----------------------------------------------------------------------------------------------------------');
    mmRaspagem.Lines.Add('');

    posicao := pos('Publicação: ', texto);
    texto := copy(texto, posicao+1);
  end;
end;

procedure TPrincipalFrm.rdbAndamentoClick(Sender: TObject);
begin
  rdbRecorte.Checked := not rdbAndamento.Checked;
end;

procedure TPrincipalFrm.rdbRecorteClick(Sender: TObject);
begin
  rdbAndamento.Checked := not rdbRecorte.Checked;
end;

function TPrincipalFrm.removerTag(texto, inicioTag, fimTag: string): string;
var
  posAuxiliar : integer;
  textoAuxiliar : string;
begin
//REMOVE O HTML QUE ESTA NO MEIO DA STRING
  posAuxiliar := pos(inicioTag,texto);
  textoAuxiliar := Copy(texto,0,posAuxiliar-1);
  posAuxiliar := pos(fimTag,texto)+fimTag.Length;
  texto:= textoAuxiliar + copy(texto,posAuxiliar);
  result := texto;

end;

procedure TPrincipalFrm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  lCodigo.Free;
  lCaracter.Free;
end;

end.
