---
tags:
  - source
  - matlab
  - pipeline
  - legacy
---

# Source: pipeline.m

[Открыть локальный файл](file:///Users/mihailkoseev/Desktop/Projects/hackrf-matlab-spectrum/matlab/pipeline.m)

Путь в проекте:

```text
matlab/pipeline.m
```

## Роль

Текущая входная точка старой версии программы.

## Текущее состояние

Pipeline пока создаёт `RealtimeWasserfall` и вызывает у него чтение metadata, чтение IQ и отрисовку.

```matlab
wasserfall = RealtimeWasserfall();

while true
    line = wasserfall.readMetadata();
    wasserfall.readIQ();
    wasserfall.drawWasserfall(...);
end
```

## Следующий этап

Подключить `Configurator` и новый источник данных перед выделением математического блока.

## Связанные заметки

- [[20 - Старый и новый pipeline]]
- [[13 - Следующие шаги]]
- [[21 - Исходники проекта]]

