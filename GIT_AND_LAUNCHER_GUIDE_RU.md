# Публикация Order of the Lion Guild Manager через GitHub и OctoLauncher

## Текущая версия

```text
1.4.1
```

## Простое обновление через сайт GitHub

1. Распакуй архив `OrderOfTheLionGM-Git-ready-v1.4.1.zip`.
2. Открой папку `OrderOfTheLionGM` внутри архива.
3. В текущем репозитории открой **Add file → Upload files**.
4. Перетащи всё содержимое папки, не создавая новый репозиторий.
5. В сообщении коммита напиши:

```text
Update to v1.4.1
```

6. Нажми **Commit changes**.

Файлы `.toc` и `.lua` должны по-прежнему находиться в корне репозитория.

## Новый GitHub Release

Создай новый релиз, не удаляя старый:

```text
Tag: v1.4.1
Title: Order of the Lion Guild Manager v1.4.1
File: OrderOfTheLionGM-v1.4.1.zip
```

Отметь его как последний релиз и опубликуй.

## Команды Git для тех, кто использует Git локально

```powershell
git add .
git commit -m "Release v1.4.1"
git push
git tag v1.4.1
git push origin v1.4.1
```

## OctoLauncher

Текущий источник аддона:

```ts
{ git: 'https://github.com/Relyway/OrderOfTheLionGM.git' },
```

При пользовательской установке OctoLauncher клонирует текущую ветку репозитория. После загрузки файлов v1.4.1 пользователи смогут получить обновление из того же источника.
