# Скрипт для блока создания кусочков файлов из GNU Radio
# Made by russkiylis, 2026

# Импорты
import os                                   # Для работы с папками
import json                                 # Для работы с json (метаданные)
import queue                                # Для очереди записи
import threading                            # Для многопоточности
from datetime import datetime, timezone     # Для задания времени
import numpy                                # GNU Radio отдаёт массивы numpy
from gnuradio import gr                     # Подключение GNU Radio

# Класс блока GNU Radio
class blk(gr.sync_block):

    # Конструктор класса
    def __init__(
            self,
            file_dir="/media/psf/hackrf-matlab-spectrum/iq-files",      # Папка вывода файлов
            sampling_rate=20e6,                                         # Частота дискретизации
            center_freq=2.4e9,                                          # Центральная частота
            bandwidth=20e6,                                             # Ширина полосы обзора
            chunk_time=0.1,                                             # Время записи в один кусок
            queue_depth=4,                                              # Глубина очереди записи
    ):
        # Встроенный конструктор GNU Radio
        gr.sync_block.__init__(
            self,
            name="Chunked File Sink",       # Название блока
            in_sig=[numpy.complex64],       # То, что входит в блок
            out_sig=[],                     # То, что выходит из блока
        )

        # Ввод переменных в атрибуты класса
        self.file_dir = os.path.abspath(os.path.expanduser(file_dir))
        os.makedirs(self.file_dir, exist_ok=True)   # Создание папки, если таковой нету
        self.metadata_path = os.path.join(self.file_dir, "metadata.jsonl")
        self.metadata_file = None
        self.sampling_rate = float(sampling_rate)

        self._center_freq = float(center_freq)
        self._bandwidth = float(bandwidth)
        self.chunk_center_freq = self._center_freq
        self.chunk_bandwidth = self._bandwidth
        self.need_new_chunk = False                 # Флажок, говорящий о том, что у нас изменились параметры и срочно требуется новый кусочек

        self.chunk_time = float(chunk_time)
        self.chunk_samples = max(1, int(self.chunk_time * self.sampling_rate))

        # Добавление очередей
        self.queue_depth = max(2, int(queue_depth))                 # Максимальный размер очереди
        self.free_queue = queue.Queue(maxsize=self.queue_depth)     # Очередь свободных буферов
        self.write_queue = queue.Queue(maxsize=self.queue_depth)    # Очередь готовых буферов. Их надо записать

        # Создание пустых буферов (массивов IQ)
        for _ in range(self.queue_depth):
            chunk_buffer = numpy.empty(self.chunk_samples, dtype=numpy.complex64)
            self.free_queue.put(chunk_buffer)

        self.buffer = self.free_queue.get()
        self.buffer_fill = 0    # Количество положенных IQ в буфер

        # Создание атрибутов нумерации кусочков
        self.chunk_id = 0           # Идентификатор кусочка
        self.first_sample_id = 0    # Идентификатор первого IQ внутри кусочка с момента начала записи

        # Служебные атрибуты для многопоточности
        self.stop_token = object()
        self.writer_thread = None


    # Метод, вызываемый при старте блока
    def start(self):
        self.metadata_file = open(self.metadata_path, "a")

        # Создание и запуск потока
        self.writer_thread = threading.Thread(target=self.writer_loop, daemon=True)
        self.writer_thread.start()

        return True


    # Цикл записи в потоке
    def writer_loop(self):
        while True:
            item = self.write_queue.get()   # Берём из очереди на запись

            if item is self.stop_token:     # Если там стоп-токен, то останавливаемся
                break

            iq, n_samples, metadata = item

            try:
                self.write_chunk_to_disk(iq, n_samples, metadata)
            finally:
                self.free_queue.put(iq)


    # Основной рабочий метод блока
    def work(self, input_items, output_items):
        input_iq = input_items[0]    # IQ, поступающие в блок
        input_position = 0           # Позиция ввода (откуда во входном массиве копируем)

        # Проверка на необходимость создания нового кусочка из-за изменения параметров center_freq или bandwidth
        if self.need_new_chunk:
            if self.buffer_fill > 0:
                self.write_chunk(self.buffer_fill)

            self.chunk_center_freq = self._center_freq
            self.chunk_bandwidth = self._bandwidth
            self.need_new_chunk = False

        while input_position < len(input_iq):
            free_space = self.chunk_samples - self.buffer_fill      # Свободное место в кусочке
            samples_left = len(input_iq) - input_position           # Сколько осталось IQ на входе
            samples_to_copy = min(free_space, samples_left)          # Сколько надо скопировать IQ

            # Копирование в буфер поданных на вход блока IQ
            self.buffer[
                self.buffer_fill : self.buffer_fill + samples_to_copy
            ] = input_iq[
                input_position : input_position + samples_to_copy
            ]

            # Увеличение количества заполненных символов буфера на количество скопированных символов
            self.buffer_fill += samples_to_copy
            input_position += samples_to_copy

            # Если буфер заполнился на максимум, то пора заливать всё это в файл
            if self.buffer_fill == self.chunk_samples:
                self.write_chunk(self.chunk_samples)

        return len(input_iq)


    # Передача готового буфера в очередь записи
    def write_chunk(self, n_samples):
        n_samples = int(n_samples)

        # Создание словаря метаданных
        metadata = {
            "chunk_id": self.chunk_id,
            "file": f"chunk_{self.chunk_id:012d}.cf32",
            "format": "cf32_le",
            "sampling_rate": self.sampling_rate,
            "center_freq": self.chunk_center_freq,
            "bandwidth": self.chunk_bandwidth,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "first_sample_id": self.first_sample_id,
            "samples_count": n_samples,
            "chunk_time": self.chunk_time,
            "duration": n_samples / self.sampling_rate,
        }

        self.write_queue.put((self.buffer, n_samples, metadata))    # Засовываем буфер в очередь записи

        self.buffer = self.free_queue.get()
        self.buffer_fill = 0

        self.chunk_id += 1
        self.first_sample_id += n_samples

    # Запись IQ в кусочек файла
    def write_chunk_to_disk(self, iq, n_samples, metadata):
        file_name = metadata["file"]                                    # Создаём кусочку имя
        file_path = os.path.join(self.file_dir, file_name)              # Путь к кусочку
        file_name_temp = file_name + ".tmp"                             # Имя незавершённого файла
        file_path_temp = os.path.join(self.file_dir, file_name_temp)    # Путь к незавершённому кусочку

        # Открываем файл и записываем в него комплексные значения как последовательность из float32 (I Q I Q I Q)
        with open(file_path_temp, "wb") as file:
            iq[:n_samples].view(numpy.float32).tofile(file)

        # Переименовываем файл, убирая приписку .tmp
        os.replace(file_path_temp, file_path)

        # Засовывание метаданных в jsonl
        self.metadata_file.write(json.dumps(metadata) + "\n")
        self.metadata_file.flush()

        print("Chunk", metadata["chunk_id"], "written:", file_path)


    # Метод stop вызывается при остановке GNU Radio
    def stop(self):
        if self.buffer_fill > 0:
            self.write_chunk(self.buffer_fill)

        self.write_queue.put(self.stop_token)

        if self.writer_thread is not None:
            self.writer_thread.join()
            self.writer_thread = None

        if self.metadata_file is not None:
            self.metadata_file.close()
            self.metadata_file = None

        return True

    # Далее идут механизмы обработки изменения центральной частоты или ширины
    # Теперь можно обращаться к методу как к обычной переменной
    @property
    def center_freq(self):
        return self._center_freq

    # Теперь можно обращаться к методу как к обычной переменной
    @property
    def bandwidth(self):
        return self._bandwidth

    # setter вызывается, когда задается center_freq
    @center_freq.setter
    def center_freq(self, value):
        new_value = float(value)

        if new_value != self._center_freq:
            self._center_freq = new_value
            self.need_new_chunk = True

    # setter вызывается, когда задается bandwidth
    @bandwidth.setter
    def bandwidth(self, value):
        new_value = float(value)

        if new_value != self._bandwidth:
            self._bandwidth = new_value
            self.need_new_chunk = True
