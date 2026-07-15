# Публикация Order of the Lion Guild Manager через Git и OctoLauncher

## Текущая версия

```text
1.0.9
```

## Первая публикация

```powershell
git init
git branch -M main
git add .
git commit -m "Release v1.0.9"
git remote add origin https://АДРЕС-РЕПОЗИТОРИЯ.git
git push -u origin main
git tag v1.0.9
git push origin v1.0.9
```

## Следующее обновление

Перед новым релизом поменяй версию минимум в:

```text
Core.lua
Advanced.lua
UI.lua
Events.lua
OrderOfTheLionGM.toc
README.txt
CHANGELOG.txt
```

После этого:

```powershell
git add .
git commit -m "Release vНОВАЯ_ВЕРСИЯ"
git push
git tag vНОВАЯ_ВЕРСИЯ
git push origin vНОВАЯ_ВЕРСИЯ
```

## OctoLauncher

Пример записи для поддерживаемого списка источников:

```ts
{ git: 'https://octowow.st/git/USERNAME/OrderOfTheLionGM.git' },
```

Lua-аддон сам не скачивает обновления из интернета. Для автоматических обновлений нужен источник в OctoLauncher.
