# Configuration Cloud avec Ansible

Ce dossier contient les configurations Ansible pour provisionner automatiquement vos environnements de développement cloud.

## 🚀 Environnements Supportés

### 1. Ubuntu Dev
- **K3s** : Kubernetes léger
- **ArgoCD** : GitOps pour la gestion des déploiements
- **Coder** : Environnements de développement
- **Podman** : Gestion des conteneurs

### 2. Rocky Dev
- **K3s** : Kubernetes léger
- **ArgoCD** : GitOps pour la gestion des déploiements
- **Coder** : Environnements de développement
- **Podman** : Gestion des conteneurs

### 3. Dockgit
- **Forgejo** : Git self-hosted (alternative à GitLab)
- **Harbor** : Registry de conteneurs privé
- **Podman** : Gestion des conteneurs

## 📋 Prérequis

- **Ansible** installé sur votre machine locale
- Accès SSH au serveur cible
- Privilèges sudo sur le serveur cible

### Installation d'Ansible

**macOS (avec Homebrew) :**
   ```bash
brew install ansible
   ```

**Ubuntu/Debian :**
   ```bash
sudo apt-get update
sudo apt-get install ansible
   ```

**CentOS/RHEL/Rocky :**
   ```bash
sudo yum install ansible
# ou
sudo dnf install ansible
```

## 🔧 Utilisation

### Méthode 1 : Script Interactif (Recommandé)

```bash
cd cloud
chmod +x configure.sh
./configure.sh
```

Le script vous guidera à travers :
1. Choix de l'environnement
2. Saisie de l'adresse IP
3. Saisie du nom d'utilisateur
4. Choix de la méthode d'authentification (mot de passe ou clé SSH)

### Méthode 2 : Scripts Spécifiques

**Pour Ubuntu Dev :**
```bash
cd cloud/ubuntu-dev/scripts
chmod +x provision.sh
./provision.sh
```

**Pour Rocky Dev :**
```bash
cd cloud/rocky-dev/scripts
chmod +x provision.sh
./provision.sh
```

**Pour Dockgit :**
```bash
cd cloud/dockgit/scripts
chmod +x provision.sh
./provision.sh
```

### Méthode 3 : Ligne de Commande Directe

```bash
cd cloud
./configure.sh ubuntu-dev
./configure.sh rocky-dev
./configure.sh dockgit
```

## 🔐 Méthodes d'Authentification

### Authentification par Mot de Passe
- Saisissez le mot de passe quand demandé
- Le mot de passe sera utilisé pour SSH et sudo

### Authentification par Clé SSH
- Fournissez le chemin vers votre clé privée SSH
- La clé doit être accessible en lecture
- Assurez-vous que la clé publique est déployée sur le serveur

## 📁 Structure des Dossiers

```
cloud/
├── configure.sh                 # Script principal de configuration
├── README.md                    # Ce fichier
├── ubuntu-dev/
│   ├── ansible/
│   │   ├── playbook.yml        # Playbook Ansible pour Ubuntu
│   │   └── inventory.ini       # Inventaire généré automatiquement
│   ├── scripts/
│   │   └── provision.sh        # Script de provisionnement rapide
│   └── config/
│       └── example_inventory.ini # Exemple d'inventaire
├── rocky-dev/
│   ├── ansible/
│   │   ├── playbook.yml        # Playbook Ansible pour Rocky
│   │   └── inventory.ini       # Inventaire généré automatiquement
│   ├── scripts/
│   │   └── provision.sh        # Script de provisionnement rapide
│   └── config/
│       └── example_inventory.ini # Exemple d'inventaire
└── dockgit/
    ├── ansible/
    │   ├── playbook.yml        # Playbook Ansible pour Dockgit
    │   └── inventory.ini       # Inventaire généré automatiquement
    ├── scripts/
    │   └── provision.sh        # Script de provisionnement rapide
    └── config/
        └── example_inventory.ini # Exemple d'inventaire
```

## 🎯 Après le Provisionnement

### Ubuntu Dev / Rocky Dev

Une fois le provisionnement terminé, vous aurez accès à :

- **ArgoCD** : `http://VOTRE_IP:8090`
  - Username : `admin`
  - Password : Affiché à la fin du provisionnement
  - Pour exposer : `sudo kubectl port-forward --address 0.0.0.0 svc/argocd-server 8090:80 -n argocd`

- **Coder** : 
  - Lancer : `coder server`
  - En arrière-plan : `nohup coder server > coder.log 2>&1 &`

### Dockgit

Une fois le provisionnement terminé, vous aurez accès à :

- **Harbor** : `https://VOTRE_IP`
  - Username : `admin`
  - Password : `Harbor12345`

- **Forgejo** : `http://VOTRE_IP:3001`

## 🔧 Personnalisation

### Modifier les Playbooks

Les playbooks Ansible se trouvent dans `cloud/[ENV]/ansible/playbook.yml`. Vous pouvez les modifier pour :

- Changer les versions des logiciels
- Ajouter des configurations supplémentaires
- Modifier les ports ou les chemins

### Utiliser des Inventaires Personnalisés

Si vous préférez créer manuellement vos inventaires :

1. Copiez `config/example_inventory.ini` vers `ansible/inventory.ini`
2. Modifiez les valeurs selon vos besoins
3. Exécutez : `ansible-playbook -i inventory.ini playbook.yml`

## 🐛 Dépannage

### Erreurs de Connexion SSH
- Vérifiez que l'adresse IP est correcte
- Vérifiez que l'utilisateur existe sur le serveur
- Vérifiez que SSH est activé et accessible
- Pour les clés SSH, vérifiez les permissions (600 pour la clé privée)

### Erreurs de Privilèges
- Assurez-vous que l'utilisateur a les privilèges sudo
- Vérifiez que le mot de passe sudo est correct

### Erreurs Ansible
- Vérifiez que tous les prérequis sont installés
- Consultez les logs détaillés avec `-vvv` : `ansible-playbook -i inventory.ini playbook.yml -vvv`

## 📞 Support

En cas de problème :
1. Vérifiez les logs de provisionnement
2. Consultez la documentation Ansible
3. Vérifiez la connectivité réseau vers le serveur cible
