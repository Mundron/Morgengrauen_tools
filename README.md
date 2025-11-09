# Sammlung von Skripten für das MUD **Morgengrauen**

## Inhalt
- [Erstinstallation](#erstinstallation)
- [Migration von `MG_tools_public`](#migration-von-mg_tools_public)
- [Hinweise zur Dateimigration](#hinweise-zur-dateimigration)

---

## Erstinstallation

1. Öffne den **Modul-Manager** (`Alt+I`).
2. Installiere das Modul **`Install_Mundron_Skripte`**.

Das Modul prüft automatisch, welche Module aus diesem Repository fehlen, und installiert sie.

---

## Migration von `MG_tools_public`

Vorgehen wie bei der Erstinstallation:

1. Füge das Modul **`Install_Mundron_Skripte`** hinzu.
2. Nach dem Hinzufügen führt es automatisch folgende Schritte aus:
   1. **Profildateien migrieren** und veraltete Dateien löschen.
   2. **Spieldateien migrieren** und veraltete Dateien löschen.
   3. **Module prüfen**: alte Module entfernen und die Neuen hinzufügen.

---

## Hinweise zur Dateimigration

- Das Skript versucht zunächst, den **Pfad des alten Repositories** zu ermitteln – Annahme: **beide Repositories liegen im selben Verzeichnis**.
- Trifft das nicht zu, sucht das Skript die **Spieldateien im neuen Repository als Backup**.  
  Kopiere in diesem Fall deine **alten Spieldateien vor dem Hinzufügen** des Installationsmoduls in das Backup-Verzeichnis des neuen Repositories, damit die Migration erfolgreich ist.