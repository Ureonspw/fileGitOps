# 🚀 Guide de Démarrage Rapide

## Installation et Configuration en 3 Étapes

### 1️⃣ Installer les Dépendances
```bash
cd cloud
./install_dependencies.sh
```

### 2️⃣ Valider la Configuration
```bash
./validate.sh
```

### 3️⃣ Lancer le Provisionnement
```bash
./launch.sh
```

## 🎯 Provisionnement Direct

### Ubuntu Dev (K3s + ArgoCD + Coder + Podman)
```bash
./configure.sh ubuntu-dev
```

### Rocky Dev (K3s + ArgoCD + Coder + Podman)
```bash
./configure.sh rocky-dev
```

### Dockgit (Forgejo + Harbor + Podman)
```bash
./configure.sh dockgit
```

## 🔧 Scripts Utiles

### Tester la Connectivité
```bash
./test_connection.sh ubuntu-dev
```

### Nettoyer les Fichiers Temporaires
```bash
./cleanup.sh
```

### Voir l'Aide
```bash
./launch.sh --help
```

## 📋 Informations de Connexion

### Méthodes d'Authentification Supportées
- ✅ **Mot de passe SSH/sudo**
- ✅ **Clé SSH privée**

### Informations Requises
- 🌐 **Adresse IP** du serveur
- 👤 **Nom d'utilisateur** SSH
- 🔐 **Mot de passe** ou **chemin vers la clé SSH**

## 🎉 Après le Provisionnement

### Ubuntu Dev / Rocky Dev
- **ArgoCD** : `http://VOTRE_IP:8090` (admin / mot de passe affiché)
- **Coder** : Lancer avec `coder server`

### Dockgit
- **Harbor** : `https://VOTRE_IP` (admin / Harbor12345)
- **Forgejo** : `http://VOTRE_IP:3001`

## 🆘 En Cas de Problème

1. **Vérifiez la connectivité** : `./test_connection.sh`
2. **Consultez les logs** : `tail -f /tmp/ansible.log`
3. **Nettoyez et recommencez** : `./cleanup.sh && ./launch.sh`

## 📚 Documentation Complète

Pour plus de détails, consultez le [README.md](README.md).
