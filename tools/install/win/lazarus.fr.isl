#include "compiler:Languages\French.isl"

[CustomMessages]


DelUserConf=Supprimer tous les fichiers de configuration de l'utilisateur provenant d'installations pr�c�dentes
CleanUp=Nettoyer: 

InstallQt=Installer la DLL de l'interface QT
InstallChm=Installer les fichiers d'aide CHM
AssociateGroup=Associer les extensions de fichiers

CheckSecondClick=Cr�er une nouvelle installation secondaire
CheckSecondInfo=Une installation secondaire permet d'installer plusieurs versions de Lazarus. Chaque version aura sa propre configuration. Veuillez lire la FAQ sur les installations multiples avant d'utiliser cette option.

FolderHasSpaces=Le nom du dossier s�lectionn� contient des espaces : veuillez s�lectionner un dossier sans espaces dans son chemin ou son nom.
FolderNotEmpty=Le dossier de destination n'est pas vide. Voulez-vous continuer l'installation ?
FolderNotEmpty2=Le dossier de destination n'est pas vide.

FolderForSecondNoFile=Le dossier de destination n'est pas vide et ne contient pas d'installation secondaire de Lazarus pouvant �tre mise � jour.%0:sVeuillez choisir un dossier vide ou un dossier avec une installation secondaire existante de Lazarus � mettre � jour.
FolderForSecondBadFile=Le dossier de destination n'est pas vide. Le programme d'installation ne pourrait pas d�tecter s'il contient une installation secondaire de Lazarus pouvant �tre mise � jour.%0:sVeuillez choisir un dossier vide ou un dossier avec une installation secondaire existante de Lazarus � mettre � jour.
FolderForSecondUpgrading=Le dossier de destination n'est pas vide.%0:sIl contient une installation secondaire de Lazarus utilisant le dossier suivant pour la configuration : %0:s%1:s%0:s%0:sVoulez-vous continuer l'installation ?
FolderForSecondUpgradingPrimary=Le dossier de destination n'est pas vide.%0:sIl contient une installation (non secondaire) par d�faut de Lazarus.%0:sSi vous continuez, il sera modifi� en une installation secondaire.%0:s%0:s%0:sVoulez-vous continuer l'installation ?

FolderForSecondBadUninstall=Le dossier de destination n'est pas vide. Le programme d'installation ne pourrait pas v�rifier s'il est s�r de l'utiliser.%0:sVeuillez choisir un dossier vide ou un dossier avec une installation secondaire existante de Lazarus � mettre � jour.

SecondConfCapt=S�lectionnez le dossier de configuration
SecondConfCapt2=O� voulez-vous que cette installation de Lazarus enregistre sa configuration ?
SecondConfBody=S�lectionnez un nouveau dossier vide pour que cette installation de Lazarus enregistre sa configuration, puis continuez avec 'Suivant'.

FolderForConfig=Dossier de configuration

FolderForConfNotEmpty=Le dossier s�lectionn� n'est pas vide.

AskUninstallTitle1=Installation pr�c�dente
AskUninstallTitle2=Voulez-vous ex�cuter le programme de d�sinstallation ?
BtnUninstall=D�sinstaller
ChkContinue=Continuer sans d�sinstaller

OldInDestFolder1=Une autre installation de %1:s existe dans le dossier de destination. Si vous souhaitez la d�sinstaller pr�alablement, veuillez utiliser le bouton ci-dessous.
OldInDestFolder2=
OldInDestFolder3=
OldInDestFolder4=

OldInOtherFolder1=Une autre installation de %1:s a �t� trouv�e en %2:s. Veuillez utiliser le bouton ci-dessous pour la d�sinstaller maintenant. Si vous souhaitez la conserver, veuillez cocher la case pour continuer.
OldInOtherFolder2=Avertissement: Il se peut qu'il y ait des conflits entre les diff�rentes installations et qu'elles ne fonctionnent pas correctement.
OldInOtherFolder3=Note: Vous n'avez pas choisi de dossier de configuration d�di� � cette installation.
OldInOtherFolder4=Si vous souhaitez utiliser plus d'une installation, veuillez revenir en arri�re pour cocher : "Cr�er une nouvelle installation secondaire".

OldInBadFolder1=Avertissement: Une autre installation de %1:s a �t� trouv�e en %2:s, mais le programme de d�sinstallation a �t� trouv� en %3:s. Veuillez v�rifier que le programme de d�sinstallation est correct.
OldInBadFolder2=Avertissement: Il se peut qu'il y ait des conflits entre les diff�rentes installations et qu'elles ne fonctionnent pas correctement.
OldInBadFolder3=Note: Si vous souhaitez utiliser plus d'une installation, veuillez revenir en arri�re et cocher : "Cr�er une nouvelle installation secondaire".
OldInBadFolder4=Veuillez utiliser le bouton ci-dessous pour la d�sinstaller maintenant. Si vous souhaitez la conserver, veuillez cocher la case pour continuer.

OldSecondInDestFolder1=Une autre installation de %1:s existe dans le dossier de destination. Si vous souhaitez la d�sinstaller pr�alablement, veuillez utiliser le bouton ci-dessous.
OldSecondInDestFolder2=
OldSecondInDestFolder3=Il s'agit d'une installation secondaire et le dossier pour la configuration sera conserv� : 
OldSecondInDestFolder4=%4:s

OldSecondInOtherFolder1=
OldSecondInOtherFolder2=
OldSecondInOtherFolder3=
OldSecondInOtherFolder4=

OldSecondInBadFolder1=
OldSecondInBadFolder2=
OldSecondInBadFolder3=
OldSecondInBadFolder4=

SecondTaskUpdate=Mise � jour de l'installation secondaire avec configuration dans le dossier : %0:s%1:s%2:s
SecondTaskCreate=Cr�ation de l'installation secondaire avec configuration dans le dossier : %0:s%1:s%2:s

DuringInstall=Quelques informations issues de notre FAQ : http://wiki.lazarus.freepascal.org/Lazarus_Faq/fr%0:s%0:s    Qu'est-ce que Lazarus ?%0:sLazarus est un EDI multiplateformes pour Pascal. Son slogan est "�crire une fois, compiler partout".%0:s%0:s    Comment r�duire la taille des fichiers ex�cutables ?%0:sLes fichiers binaires produits par d�faut sont volumineux parce qu'ils incluent des informations pour le d�bogage. Pour les versions de production, vous pouvez d�sactiver la production de ces informations au niveau des options du projet.%0:s%0:s    Licence : %0:s- La LCL est distribu�e sous licence LGPL avec une exception pour l'�dition de liens. Cette licence vous autorise � cr�er des applications avec la licence que vous voulez, y compris une licence commerciale. L'EDI est sous licence GPL. Si vous distribuez un EDI modifi�, vous devez suivre la GPL.%0:s- Les autres paquets et composants ont des licences vari�es. Consultez le fichier "readme" de chacun d'eux.

UninstVerbose=Vous �tes sur le point de d�sinstaller %1:s depuis le dossier %0:s. Voulez-vous continuer ?
