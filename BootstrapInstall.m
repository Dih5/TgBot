(* ::Package:: *)

Get["https://raw.githubusercontent.com/jkuczm/MathematicaBootstrapInstaller/v0.1.1/BootstrapInstaller.m"]


BootstrapInstall[
	"SyntaxAnnotations",
	"https://github.com/dih5/PhysDataFetch/releases/download/v0.1.0/TgBot.zip",
	"AdditionalFailureMessage" ->
		Sequence[
			"You can ",
			Hyperlink[
				"install the TgBot package manually",
				"https://github.com/dih5/TgBot#manual-installation"
			],
			"."
		]
]