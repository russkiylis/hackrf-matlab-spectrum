---
tags:
  - source
  - matlab
  - datasource
---

# Source: FileDataSource.m

[Открыть локальный файл](file:///Users/mihailkoseev/Desktop/Projects/hackrf-matlab-spectrum/matlab/FileDataSource.m)

Путь в проекте:

```text
matlab/FileDataSource.m
```

## Роль

Абстрактный родитель файловых источников. Хранит общий файловый механизм и защищённый метод чтения IQ.

## Ключевые фрагменты

```matlab
classdef (Abstract) FileDataSource < handle
```

```matlab
methods(Abstract)
    [iq_complex, metadata] = nextData(obj);
end
```

```matlab
methods(Access=protected)
    function iq_complex = readIQ(obj, metadata)
        ...
    end
end
```

## Связанные заметки

- [[06 - FileDataSource]]
- [[04 - Контракт источника данных]]
- [[11 - Формат IQ-данных]]
- [[21 - Исходники проекта]]

