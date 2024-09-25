unit websocket.client;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, httpsend;

type
    TWebsocketMessageType = (wmtContinue = 0, wmtString = 1, wmtBinary =2, wmtClose = 8, wmtPing = 9, wmtPong = 10);

    TWebsocketFrame=record
                          FIN: Boolean;
                          opcode: TWebsocketMessageType;
                          payload: AnsiString;
    end;

    TWebsocketMsg=record
                        MsgType: TWebsocketMessageType;
                        payload: AnsiString;
    end;

    EWebsocketError=Exception;

    { TWebsocketClient }

    TWebsocketClient=class(THTTPSend)
          private
                 FReady: Boolean;

                 function GenerateKey: String;
                 function RecvFrame(out Frame: TWebsocketFrame): Boolean;
                 procedure SendFrame(Frame: TWebsocketFrame);
          public
                 constructor Create;
                 function Upgrade(url, proto: string): Boolean;
                 procedure Send(str: AnsiString; AsBinary: Boolean=false);
                 function WebsocketRead(out msg: TWebsocketMsg): Boolean;
                 procedure Ping;
                 destructor Destroy; override;

                property Ready: Boolean read FReady;
    end;

implementation

uses base64, sockets;

type
    TWordRec = record
             case boolean of
                  True: (Bytes: array[0..1] of byte);
                  False: (Value: word);
    end;

    TMaskRec = record
    case boolean of
      True: (Bytes: array[0..3] of byte);
      False: (Key: Cardinal);
  end;

function ntohll(net: int64): int64; inline;
begin
{$ifdef FPC_BIG_ENDIAN}
        Result := net;
{$else}
       Result := SwapEndian(net);
{$endif}
end;

function htonll(host: QWord): QWord; inline;
begin
{$ifdef FPC_BIG_ENDIAN}
  Result := host;
{$else}
  Result := SwapEndian(host);
{$endif}
end;

function boolToBit(b: boolean; Bit: byte): byte; inline;
begin
  Result := 0;
  if b then
    Result := 1 shl Bit;
end;

{ TWebsocketClient }

function TWebsocketClient.GenerateKey: String;
var
  GenKey: AnsiString;
  i: Integer;
begin
  SetLength(GenKey, 16);
  for i:=1 to 16 do
    GenKey[i] := Chr(Random(256));
  Result := EncodeStringBase64(GenKey);
end;

function TWebsocketClient.RecvFrame(out Frame: TWebsocketFrame): Boolean;
var
   w: Word;
   w2: int64;
   wordRec: TWordRec;
   payload_length: integer;
begin
     Result:=False;
     if not FReady then
        exit;
     if FSock.RecvBuffer(@w,2)<>2 then
        begin
             if (FSock.LastError<>0) AND (FSock.LastError<>11) then
                begin
                     FReady:=False;
                     raise EWebsocketError.Create('Error read from socket header: '+FSock.LastErrorDesc+' (code: '+IntToStr(FSock.LastError)+')');
                end;
             exit;
        end;
     wordRec.Value:=w;
     Frame.FIN:=(wordRec.Bytes[0] and 128)=128;
     Frame.opcode := TWebsocketMessageType(wordRec.Bytes[0] and %1111);
     hasMask:=(wordRec.Bytes[1] and 128) = 128;
     payload_length:=wordRec.Bytes[1] and %1111111;
     case payload_length of
          126: begin
                    if not FSock.RecvBufferEx(@w,2,10000)=2 then
                       begin
                            FReady:=False;
                            raise EWebsocketError.Create('Error read from socket length as word: '+FSock.LastErrorDesc);
                       end;
                    payload_length:=NToHs(w);
          end;
          127: begin
                    if not FSock.RecvBufferEx(@w2,8,10000)=8 then
                       begin
                            FReady:=False;
                            raise EWebsocketError.Create('Error read from socket length as double word: '+FSock.LastErrorDesc);
                       end;
                    payload_length:=ntohll(w2);
          end;
     end;
     SetLength(Frame.payload,payload_length);
     if FSock.RecvBufferEx(@Frame.payload[1],Length(Frame.payload),30000)<>payload_length then
        begin
             FReady:=False;
             raise EWebsocketError.Create('Error read from socket');
        end;
     Result:=True;
end;

procedure TWebsocketClient.SendFrame(Frame: TWebsocketFrame);
var
   payload_length: Byte;
   MaskRec: TMaskRec;
   i: integer;
   packet: TMemoryStream;
begin
     if not FReady then
        exit;
     packet:=TMemoryStream.Create;
     try
        MaskRec.Key:=Random(Cardinal.MaxValue+1);
        if Frame.payload.Length<126 then
           payload_length:=Frame.payload.Length
           else
           if Frame.payload.Length<=Word.MaxValue then
              payload_length:=126
              else
              payload_length:=127;
        packet.WriteByte(boolToBit(Frame.FIN, 7) or (Ord(Byte(Frame.opcode)) and %1111));
        packet.WriteByte(boolToBit(true, 7) or (payload_length and %1111111));
        case payload_length of
             126: packet.WriteWord(htons(word(Frame.payload.Length)));
             127: packet.WriteQWord(htonll(QWord(Frame.payload.Length)));
        end;
        packet.WriteDWord(MaskRec.Key);
        for i:=0 to Frame.payload.Length-1 do
            packet.WriteByte(Ord(Frame.payload[i+1]) xor MaskRec.Bytes[i mod 4]);
        if FSock.SendBuffer(packet.Memory,packet.Size)<>packet.Size then
           begin
                FReady:=False;
                raise EWebsocketError.Create('Error send frame to socket');
           end;
     finally
            packet.Free;
     end;
end;

procedure TWebsocketClient.Send(str: AnsiString; AsBinary: Boolean);
var
   frame: TWebsocketFrame;
begin
     frame.FIN:=True;
     if AsBinary then
        frame.opcode:=wmtBinary
        else
        frame.opcode:=wmtString;
     frame.payload:=str;
     SendFrame(frame);
end;

constructor TWebsocketClient.Create;
begin
     inherited Create;
     FReady:=False;
end;

function TWebsocketClient.Upgrade(url, proto: string): Boolean;
begin
     WriteLn('Start Upgrade');
     Result:=False;
     KeepAlive:=True;
     KeepAliveTimeout:=99999999;
     FStatus100:=False;
     FHeaders.Clear;
     FHeaders.CaseSensitive:=False;
     FHeaders.Add('Connection: Upgrade');
     FHeaders.Add('Upgrade: websocket');
     FHeaders.Add('Sec-WebSocket-Key: %s'.Format([GenerateKey]));
     FHeaders.Add('Sec-WebSocket-Version: 13');
     FHeaders.Add('Sec-WebSocket-Protocol: %s'.Format([proto]));
     if HTTPMethod('GET',url) then
        if ResultCode=101 then
           begin
                WriteLn('Upgrade OK');
                FReady:=True;
                Result:=True;
                FSock.NonBlockMode:=False;
                FSock.SetTimeout(1000);
           end;
     WriteLn('Upgrade result = '+IntToStr(ResultCode)+' '+ResultString);
end;

function TWebsocketClient.WebsocketRead(out msg: TWebsocketMsg): Boolean;
var
   frame: TWebsocketFrame;
begin
     Result:=False;
     if not FReady then
        exit;
     while RecvFrame(frame) do
        begin
             msg.MsgType:=TWebsocketMessageType(frame.opcode);
             msg.payload:=frame.payload;
             while not frame.FIN do
                   begin
                        if not RecvFrame(frame) then
                           raise EWebsocketError.Create('Error read next frame');
                        if frame.opcode<>wmtContinue then
                           raise EWebsocketError.Create('Wait continue frame, but reacv = '+IntToStr(Byte(frame.opcode)));
                        msg.payload+=frame.payload;
                        if frame.FIN then
                           Break;
                      end;
             case msg.MsgType of
                  wmtPing: begin
                                frame.opcode:=wmtPong;
                                frame.payload:=msg.payload;
                                frame.FIN:=True;
                                SendFrame(frame);
                  end;
                  wmtPong: ; // just ignore
                  wmtClose: begin
                                 FReady:=False;
                                 FSock.CloseSocket;
                                 Exit;
                  end;
                  wmtContinue: raise EWebsocketError.Create('Out of order continue message');
                  wmtString: begin
                                  Result:=True;
                                  Break;
                  end;
                  wmtBinary: begin
                                  Result:=True;
                                  Break;
                  end;
             end;
        end;
end;

procedure TWebsocketClient.Ping;
var
   frame: TWebsocketFrame;
begin
     frame.FIN:=True;
     frame.opcode:=wmtPing;
     frame.payload:='ping';
     SendFrame(frame);
end;

destructor TWebsocketClient.Destroy;
begin

     inherited Destroy;
end;

end.
