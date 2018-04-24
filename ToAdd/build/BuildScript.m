(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



BeginPackage["SharedPacletServer`"];


SharedPacletServerRebuild::usage=
	"Rebuilds and pushes the paclet server";


BeginPackage["`Package`"];


SharedPacletServerAddPaclets::usage="";
SharedPacletServerBuild::usage="";
SharedPacletServerTest::usage="";
SharedPacletServerPush::usage="";


EndPackage[];


Begin["`Private`"];


$PacletServerAddAsSite=False;
Internal`WithLocalSettings[
	If[
		Set[
			$PacletServerAddAsSite,
			Not@
				MemberQ[
					PacletSites[], 
					PacletSite["http://raw.githubusercontent.com/paclets/PacletServer/master", __]
					]
			],
		PacletManager`PacletSiteAdd[
			"http://raw.githubusercontent.com/paclets/PacletServer/master"
			];
		],
	PacletManager`PacletCheckUpdate[
		"BTools"
		],
	If[$PacletServerAddAsSite, 
		PacletManager`PacletSiteRemove[
			"http://raw.githubusercontent.com/paclets/PacletServer/master"
			]
		]
	]


<<BTools`External`
<<BTools`Paclets`


$ToAddDir=
	ParentDirectory@DirectoryName@$InputFileName;


$PacletServerDir=
	Nest[ParentDirectory, DirectoryName@$InputFileName, 2];


Clear[
	SharedPacletServerAddPaclets, 
	SharedPacletServerBuild, 
	SharedPacletServerPush,
	SharedPacletServerRebuild
	]


gitLogMDKV[key_, val_DateObject?DateObjectQ]:=
	"* "<>ToString[key]<>": "<>DateString[val, "DateTime"];
gitLogMDKV[key_, val_]:=
	"* "<>ToString[key]<>": "<>ToString[val];
gitLogMDLog[a:{__Association}]:=
	StringRiffle[
		"*** Commit: "<>#Commit<>" ***\n"<>
			StringRiffle[
				KeyValueMap[gitLogMDKV, KeyDrop[#, {"Message", "Commit"}]], 
				"\n"]&/@a, 
		"\n\n"
		];
gitLogMDBit[name_String, a:{__Association}]:=
	"<a id=\"`Name`\" style=\"width:0;height:0;margin:0;padding:0;\">&zwnj;</a>
## `Name`

`Log`

"~TemplateApply~
	<|
		"Log"->gitLogMDLog[a], 
		"Name"->name
		|>;
gitLogMD[a_Association]:=
	"# Git Commit Log

``
"~TemplateApply~StringRiffle[KeyValueMap[gitLogMDBit, a], "\n<hr/>\n"];


(* ::Text:: *)
(*Not quite there yet. In particular the mapping over every commit piece might not fully work yet.*)



pacletServerAttachLogMD[]:=
	Module[
		{
			fds=
				Normal@
					Git["FileHistory", 
						$PacletServerDir, 
						"Paclets/*.paclet",
						"FullHistory"->True
						],
			gitLogVals
			},
			gitLogVals=
				Values@*Merge[First@*First]/@
					GroupBy[
						Normal@fds,
						StringSplit[
							StringTrim[#[[1]] ,"Paclets/"],
							"-"
							][[1]]&->Last
						];
			Export[
				FileNameJoin@{$PacletServerDir, "content", "pages", "log.md"},
				gitLogMD[gitLogVals],
				"Text"
				]
			]


Options[SharedPacletServerAddPaclets]=
	Join[
		{
			"ExportGitLog"->True
			},
		Options[PacletServerAdd]
		];
SharedPacletServerAddPaclets[ops:OptionsPattern[]]:=
	Append[
		Map[
			Function[
				With[{psa=
					PacletServerAdd[$PacletServerDir, #, 
						FilterRules[{ops}, Options[PacletServerAdd]]
						]},
					CopyFile[#, 
						FileNameJoin@{DirectoryName[#], "last_build", FileNameTake[#]},
						OverwriteTarget->True
						]->
					(DeleteFile[#];psa)
					]
				],
			Join[
				Select[
					FileExistsQ[FileNameJoin[{#, "PacletInfo.m"}]]||
						FileExistsQ[FileNameJoin[{#, FileBaseName[#]<>".m"}]]&
					]@
					FileNames[
						"*",
						$ToAddDir
						],
				FileNames[
					"*.paclet",
					$ToAddDir
					]
				]
			],
		If[TrueQ@OptionValue["ExportGitLog"],
			pacletServerAttachLogMD[],
			Nothing
			]
		];


SharedPacletServerBuild[ops:OptionsPattern[]]:=
	PacletServerBuild[$PacletServerDir,
	 FilterRules[{ops}, Options[PacletServerBuild]]
	 ];


SharedPacletServerPush[ops:OptionsPattern[]]:=
	With[{dir=$PacletServerDir},
		Git["Commit", 
			dir,
			FilterRules[
				{
					ops,
					"Message"->TemplateApply["Rebuilt on ``", DateString[]],
					"All"->True
					},
				Git["Commit", "Options"]
				]
			];
		GitHub["Push", dir]
		];


SharedPacletServerTest[]:=
	PySimpleServerOpen[
		PacletServerExecute["Path", $PacletServerDir, "docs"]
		]


$ServerRebuildKeys=
	"Add"|"Build"|"Push"|"Test";


SharedPacletServerRebuild[do:{$ServerRebuildKeys..}:{"Add", "Build", "Push"},
	ops:OptionsPattern[]
	]:=
	Block[
		{
			res=<||>
			},
		If[MemberQ[do, "Add"],
			PrintTemporary[Internal`LoadingPanel["Adding paclets..."]];
			res["Add"]=
				SharedPacletServerAddPaclets[
					FilterRules[{ops}, Options[SharedPacletServerAddPaclets]]
					]
			];
		If[MemberQ[do, "Build"],
			PrintTemporary[Internal`LoadingPanel["Building pages..."]];
			res["Build"]=
				SharedPacletServerBuild[
					FilterRules[{ops}, Options[SharedPacletServerBuild]]
					]
			];
		If[MemberQ[do, "Test"],
			SharedPacletServerTest[]
			];
		If[MemberQ[do, "Push"],
			PrintTemporary[Internal`LoadingPanel["Pushing to GitHub..."]];
			res["Push"]=
				SharedPacletServerPush[
					FilterRules[{ops}, Options[SharedPacletServerPush]]
					]
			];
		res
		];
SharedPacletServerRebuild[do:$ServerRebuildKeys, 
	ops:OptionsPattern[]
	]:=
	SharedPacletServerRebuild[{do}, ops]


End[];


EndPackage[];



