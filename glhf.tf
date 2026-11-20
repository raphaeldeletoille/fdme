Controle FDME

Créer un dossier PRENOM-NOM sur votre Bureau (le contrôle se fera depuis ce dossier)
Vous indiquerez aussi votre PRENOM-NOM tout en haut de votre code en commentaire
Vous pouvez répondre aux questions de la partie 1 en comentaire dans votre main.tf ou dans un fichier texte

5 points
Partie 1)

1) Qu’est-ce qu’un cloud public, un cloud privé et un cloud hybride ? Expliquez leurs différences et donnez un exemple d’utilisation pour chacun.

2) Qu’est-ce que Microsoft Azure ? Présentez trois types de services proposés et donnez un exemple d’utilisation pour chacun.

3) Qu’est-ce que l’Infrastructure as Code (IaC) ? Expliquez ses avantages par rapport à une configuration manuelle et citez deux outils permettant de la mettre en œuvre.

4) Comment réduire les coûts d’une infrastructure sur Azure ? Proposez au moins trois actions concrètes et expliquez leurs éventuelles conséquences sur le service.

5) Quelle est la différence entre une adresse IP publique et une adresse IP privée ? Une machine virtuelle Azure sans IP publique peut-elle être accessible à distance ? Justifiez.


---------------------------------------------------------

15 points
Partie 2)
Vous utiliserez la location/région qui vous a été donné au début du cours.

Utilisez la dernière version du provider disponible, sauf pour azuread (utilisez l'avant dernière).

Toutes les ressources à déployer commenceront par les 3 premières lettres de votre nom de famille (à l'exception du resource group, exercice1)

1) Déployer un resource group avec votre première lettre de prénom suivi de votre nom de famille. (toutes les ressources sont à déployer sur ce resource group)

2) Déployer un Keyvault avec tous les droits secret au groupe utilisateur "group-etudiants" et le droit secret get à "gta6@deletoilleprooutlook.onmicrosoft.com" .

3) Déployer 2 virtual network et 3 subnets sur chacun de vos virtual network.  

4) Déployer un storage account qui favorise un accès peu fréquent à la données (sans être Archives) ainsi qu'une règle réseau pare-feu qui autorise votre IP publique et la mienne (82.123.113.93) sur ce storage.

5) Créer un storage_container dans le storage account "glhf"

6) Déployer 1 vm Ubuntu avec le sku par défaut sur votre vnet 1 subnet 3 en mode admin/password (et pas clé ssh). Vous devez pouvoir vous connecter à la VM. Activer le boot diagnostic en utilisant votre storage account.

7) Déployer 3 Disks --> un de 500Go, un de 1To, un de 2To et les connecter à votre VM. 

8) Déployer 1 log Analytics Workspace, et envoyer tous les logs (et uniquement les logs) de votre storage account dessus.

9) Donner les droits qui permettent de déployer ou détruire les ressources à l'utilisateur "gta6@deletoilleprooutlook.onmicrosoft.com" sur votre Resource Group

10) Déployer un grafana sur lequel vous pouvez vous connecter uniquement avec les droits lecture. 

BONUS) Déployer un MSSQL Server.
       Déployer une base de données (MSSQL_Database) sur votre MSSQL Server en General Purpose, Generation 5, Serverless, 1 Vcore Maximum
       Connectez vous à la base de données.
    

Lorsque votre code est terminé :

SAUVEGARDEZ vos .tf

Faites un Terraform Destroy

Aller dans le storage account "storagefdme" (rg = controle).

ALler dans le container controle

Add Directory (Votre Prénom-Nom)

Déposez votre code.tf


