---
tags:
  - source
  - matlab
  - utility
---

# Source: waitForFile.m

[Открыть локальный файл](file:///Users/mihailkoseev/Desktop/Projects/hackrf-matlab-spectrum/matlab/waitForFile.m)

Путь в проекте:

```text
matlab/waitForFile.m
```

## Роль

Небольшая функция ожидания появления файла с таймаутом.

## Почему это функция, а не класс

У действия нет самостоятельного состояния и сложного жизненного цикла. Оно получает путь и таймаут, затем либо завершается, либо выдаёт ошибку.

## Ключевой фрагмент

```matlab
while ~isfile(file_path)
    if toc(t_start) > timeout
        error(...);
    end
    pause(0.5);
end
```

## Связанные заметки

- [[02 - Пирамидальная декомпозиция]]
- [[08 - RealtimeFileDataSource]]
- [[21 - Исходники проекта]]

