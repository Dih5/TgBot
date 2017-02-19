BeginPackage["TgBot`"]

(*Basic API*)
BotAPICall::usage="BotAPICall[method, args, bot] makes the bot call a method using the given parameters.";
BotFileAPICall::usage="BotFileAPICall[method, args, filePath,fileField,bot] works like BotAPICall sending a file loaded from filePath as a parameter of name fileField.";
BotStart::usage="BotStart[pollTime, bot, botCmdList] starts a bot with the typical command/answer cycle. The commands are given by botCmdList, and updates being check every pollTime.";

(*Overridable methods*)
BotErrorNoCmd::usage="BotErrorNoCmd[msg, bot] is called by BotStart to answer a non-command message. Override if needed.";
BotErrorUnknownCmd::usage="BotErrorUnknownCmd[msg, bot] is called by BotStart to answer an unknown command message. Override if needed.";
BotErrorUnprivilegedCmd::usage="BotErrorUnprivilegedCmd[msg, bot] is called by BotStart to answer a command message beyond the user's privilege. Override if needed.";
BotLog::usage="BotLog[string] is called by BotStart to register events for debug purposes. By default calls Print. Override if needed.";

(*Convenient wrappers*)
BotAnswerMsg::usage="BotAnswerMsg[msg, txt, bot] makes the bot answer the given message with the given text.";
BotPhotoAnswerMsg::usage="BotPhotoAnswerMsg[msg, filePath, bot] makes the bot answer the given message sending the photo in filePath.";
BotAudioAnswerMsg::usage="BotAudioAnswerMsg[msg, filePath, bot] makes the bot answer the given message sending the audio in filePath.";

(*Useful tools*)
BotPrepareKeyboard::usage="BotPrepareKeyboard[strMatrix], where strMatrix is a 2D matrix of strings, prepares the serialized object representing a custom keyboard";
BotUserPrivilege::usage="BotUserPrivilege[usrId, bot] returns 0 if usrId is not registered as friend, 1 if so, and 2 if admin.";


Begin["`Private`"]
(* Implementation of the package *)

$CharacterEncoding = "UTF-8";

JSONElement::usage="JSONElement[json, {a_1,a_2,...,a_n}] gets the element a_n in element a_n-1... in element a_1 in the given json object.";
(*TODO: Handle errors*)
JSONElement[json_, lst_List] := Fold[#2 /. #1 &, json, lst]
JSONElement[json_, s_String] := s /. json


(*Temporal storage for unfinished commands.
 Each element introduced must be of the form {userId, strBuffered}
*)
CmdBuffer ={};

BotLog[str_]:=Print[str]



BotUserPrivilege[usrId_, bot_] :=
    If[ MemberQ[JSONElement[bot,"MasterList"], usrId],
        2,
        If[ MemberQ[JSONElement[bot,"FriendList"], usrId],
            1,
            0
        ]
    ]
    

(*Compatibility version of URLQueryEncode*)
If[$VersionNumber < 10.0,
URLQueryEncode[strMatrix_] := 
 StringJoin@
  Riffle[StringJoin[#[[1]], "=", #[[2]]] & /@ 
    Map[StringReplace[ToString[#], {" " -> "+", "!" -> "%21", "#" -> "%22", 
        "$" -> "%24", "&" -> "%26", "'" -> "%27", "(" -> "%28", 
        ")" -> "%29", "*" -> "%2A", "+" -> "%2B", "," -> "%2C", 
        "/" -> "%2F", ":" -> "%3A", ";" -> "%3B", "=" -> "%3D", 
        "?" -> "%3F", "@" -> "%40", "[" -> "%5B", "]" -> "%5D"}] &, 
     strMatrix, {2}], "&"]
];

BotAPICall[method_String, args_List, bot_] :=
    Block[ {url},
        url = "https://api.telegram.org/bot" <> JSONElement[bot,"Token"] <> "/" <> method <>
           If[ args == {},
               "",
               "?" <> URLQueryEncode[args]
           ];
        Import[url, "JSON"]
    ]
  
  
BotFileAPICall[method_String, args_List, filePath_String,fileField_String,bot_] :=
    Block[ {url,bytes,filename},
    	bytes=Import[filePath,"Byte"];
    	filename=StringJoin[FileBaseName[filePath],".",FileExtension[filePath]];
         url = "https://api.telegram.org/bot" <> JSONElement[bot,"Token"] <> "/" <> method <>
           If[ args == {},
               "",
               "?" <> URLQueryEncode[args]
           ];
        If[$VersionNumber<10.0,
        BotLog["ERROR: BotFileAPICall does not work in v < 10.0."]	,
        (*Original idea taken from http://mathematica.stackexchange.com/questions/52338/more-complete-mutipartdata-posts-using-urlfetch *)
        URLExecute[url,{},"JSON","Method"->"POST","MultipartElements"->{{fileField<>"\"; filename=\""<>filename,"application/octet-stream",bytes}},"Headers"->{"Accept"->"application/json; charset=UTF-8","Content-Type"->"multipart/form-data"}]
        ]
    ]

BotAnswerMsg[msg_, txt_String, bot_] :=
    Block[ {fromid, msgId},
        fromid = JSONElement[msg,{"message","from","id"}];
        msgId = JSONElement[msg,{"message","message_id"}];
        BotAPICall[
         "sendMessage", {"chat_id" -> fromid, "text" -> txt, 
          "reply_to_message_id" -> msgId}, bot]
    ]
    
BotPhotoAnswerMsg[msg_, filePath_String, bot_] :=
    Block[ {fromid, msgId},
        fromid = JSONElement[msg,{"message","from","id"}];
        msgId = JSONElement[msg,{"message","message_id"}];
        BotFileAPICall[
         "sendPhoto", {"chat_id" -> fromid, 
          "reply_to_message_id" -> msgId},filePath ,"photo",bot]
    ]
    
BotAudioAnswerMsg[msg_, filePath_String, bot_] :=
    Block[ {fromid, msgId},
        fromid = JSONElement[msg,{"message","from","id"}];
        msgId = JSONElement[msg,{"message","message_id"}];
        BotFileAPICall[
         "sendAudio", {"chat_id" -> fromid, 
          "reply_to_message_id" -> msgId},filePath ,"audio",bot]
    ]

BotPrepareKeyboard[strMatrix_] := "{\"keyboard\":" <> StringReplace[ExportString[strMatrix, "JSON"], {"\n" -> "", "\t" -> ""}] <> "}"

ProcessMessage::usage="ProcessMessage[msg, bot, BotCmdList] makes the bot automatically process a message with the rules given in BotCmdList.";
ProcessMessage[msg_, bot_, BotCmdList_] :=
    Block[ {txt, cmd, usrId, cmdEntry,cmdReturn,msg2},
    	usrId = JSONElement[msg,{"message","from","id"}];
    	(*If a command was not processed due to lack of arguments, append msg to buffered cmd*)
        txt = GetPartialCommand[usrId,True] <> JSONElement[msg,{"message","text"}];
        msg2=msg/.{("text" -> _) -> ("text" -> txt)};
		BotLog["Answering command: "<> txt];
        cmd = StringDrop[#, 1] & /@ 
          StringCases[txt, StartOfString ~~ "/" ~~ ((WordCharacter | "_") ..), 1];
        If[ Length[cmd] == 0,
            BotErrorNoCmd[msg2,bot],
            cmdEntry = 
             Select[BotCmdList, ToLowerCase[#[[1]]] == ToLowerCase[cmd[[1]]] &];
            If[ Length[cmdEntry] == 0,
                BotErrorUnknownCmd[msg2, bot],
                If[ BotUserPrivilege[usrId, bot] < cmdEntry[[1, 2]],
                    BotErrorUnprivilegedCmd[msg2, bot],
                    cmdReturn=cmdEntry[[1, 3]][msg2,bot];
                    (*If first element of returned list is False, msg was not processed due to lack of arguments
                     Note the processed msg2 may contain previously buffered arguments *)
                    If[cmdReturn[[1]]===False,SavePartialCommand[msg2]];
                    cmdReturn
                    
                ]
            ]
        ]
    ]

BotErrorNoCmd[msg_, bot_] := {True,BotAnswerMsg[msg,JSONElement[bot, "ErrorNoCmd"],bot]}

BotErrorUnknownCmd[msg_, bot_] := {True,BotAnswerMsg[msg,JSONElement[bot, "ErrorUnknownCmd"],bot]}

BotErrorUnprivilegedCmd[msg_, bot_] := {True,BotAnswerMsg[msg,JSONElement[bot, "ErrorUnprivilegedCmd"],bot]}


BotStart[pollTime_, botPath_, BotCmdList_] :=
    Quiet[Block[ {updates, ToAnswerList, ProcessResult,bot},
              bot = Import[botPath, "JSON"];
              While[True,
              updates = BotAPICall["getUpdates", {},bot];
              If[ updates === $Failed,
                  BotLog["Failed to get updates."],
                  ToAnswerList = 
                   Select[updates[[2, 
                     2]], ("update_id" /. #) > JSONElement[bot,"LastAnswered"] &];
                  If[ ToAnswerList === {},(*Nothing to do*)
                      Null,
					  BotLog["Messages to answer: " <> ToString[ToAnswerList]];
                      ProcessResult = ProcessMessage[#, bot, BotCmdList] & /@ ToAnswerList;
                      If[ VectorQ[ProcessResult, #[[2]] === $Failed &],
					  BotLog["All reponses failed. Doing nothing."],
                          If[ AnyTrue[ProcessResult, #[[2]] === $Failed &],
					  BotLog["Some reponses failed and were discarded!!!"]
                          ];
                          bot = 
                               bot /. (("LastAnswered" -> _) -> 
                                  "LastAnswered" -> ("update_id" /. ToAnswerList[[-1]]));
                          Export[botPath, bot, "JSON"]
                      ]
                  ];
              ];
              Pause[pollTime]]
          ], {URLFetch::invhttp, FetchURL::conopen}]
          
SavePartialCommand[msg_,append_:False]:= Block[{id,txt,p},
	id=JSONElement[msg,{"message","from","id"}];
	txt=JSONElement[msg,{"message","text"}];
	BotLog["Buffering command " <> txt <> " for user " <> ToString[id] ];
	CmdBuffer = If[(p=Position[CmdBuffer[[All,1]],id])==={},
		(*No data in the buffer: add a new piece*)
		Join[CmdBuffer,{{id,txt}}],
		(*Otherwise, replace old data*)
		 CmdBuffer /. If[append,{id,part_}:>{id,txt},{id,part_}:>{id,part<>txt}]
		]

]

CleanPartialCommand[id_]:= Block[{},
	BotLog["Cleaned buffered command " <> " for user " <> ToString[id] ];
	CmdBuffer = DeleteCases[CmdBuffer, {id, _}]
]

GetPartialCommand[id_, clean_:True]:= Block[{p,str},
	If[(p=Position[CmdBuffer[[All,1]],id])==={},
		(*No data in the buffer: return empty string*)
		"",
		(*Otherwise, recover old data and clean if Needed*)
		str=CmdBuffer[[p[[1,1]],2]];If[clean===True,CleanPartialCommand[id]];str<>" "
	]

]
          

End[]

EndPackage[]

