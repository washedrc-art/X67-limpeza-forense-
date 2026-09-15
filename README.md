# X67 LIMPEZA FORENSE

Painel Termux para Android 11+ com ADB.

## Instalação e execução

Depois de colocar o ZIP no Termux:

```bash
cd ~
unzip X67-Limpeza-Forense.zip
bash ~/X67-Limpeza-Forense/install.sh
```

O `install.sh` instala automaticamente:
- android-tools (ADB)
- coreutils
- grep
- sed
- awk
- unzip

Depois inicia o painel automaticamente.

## ADB sem fio

No Android 11 ou superior, ative Depuração sem fio nas Opções do desenvolvedor.
A opção 0 orienta o pareamento e depois executa `adb connect`.

## Observação

painel criado para limpeza forense feito por x67
