---
tags:
  - source
  - matlab
  - configurator
---

# Source: Configurator.m

[Открыть локальный файл](file:///Users/mihailkoseev/Desktop/Projects/hackrf-matlab-spectrum/matlab/Configurator.m)

Путь в проекте:

```text
matlab/Configurator.m
```

## Роль

Конфигуратор выбирает конкретный источник данных по значению `config.data_source.type`.

## Ключевой фрагмент

```matlab
switch obj.data_source_config.type
    case "file_realtime"
        data_source = RealtimeFileDataSource(...);
    case "file_recorded"
        data_source = RecordedFileDataSource(...);
    otherwise
        error(...);
end
```

## Связанные заметки

- [[05 - Configurator]]
- [[03 - Текущая архитектура источников данных]]
- [[17 - Архитектурные решения]]
- [[21 - Исходники проекта]]

