# Kế hoạch xây dựng SR4Rec và công bố trên SoftwareX (bản cuối cùng)

| Mục | Nội dung |
|---|---|
| Tên phần mềm | SR4Rec (tên tạm, kiểm tra trùng ở A0.2) |
| Mục tiêu | Toolkit mã nguồn mở trả lời câu hỏi: *đặt một mô hình super-resolution (SR) trước bộ nhận dạng có làm tăng độ chính xác so với phóng to bicubic hay không?* Công bố dạng Original Software Publication trên SoftwareX |
| Người thực hiện | Thái Lê Quang |
| Ngày lập | 21/09/2026 |
| Trạng thái | **Bản cuối cùng (FINAL), thay thế mọi bản trước.** Không thay đổi phạm vi nữa. Chỉ bắt đầu implement khi có yêu cầu của người thực hiện |
| Bắt đầu | Thứ Hai 05/10/2026 (sau hạn nộp DASA'26 ngày 01/10/2026) |
| Nộp bài | 08/01/2027 (14 tuần lịch, gồm 1 tuần nghỉ lễ); dự phòng đến 22/01/2027 |
| Phần cứng | 1 GPU loại RTX 3090/4090; 1 máy CPU để đo latency |

**Nguyên tắc xuyên suốt:** mỗi quyết định chỉ giữ **một phương án**. Mọi thứ không cần để trả lời câu hỏi chính một cách đúng và tái lập được đều đưa vào mục 6 (Future work).

---

## 0. Tóm tắt

Người dùng chuẩn bị dataset theo **một format quy định**, tự tải các file trọng số SR (`.pth`), rồi chạy ba lệnh:

```bash
sr4rec init my_dataset/        # validate the dataset and write sr4rec.yaml
sr4rec run sr4rec.yaml         # full pipeline (add --dry-run to check everything first)
sr4rec reproduce quickstart    # built-in demo; also re-runs the paper demos
```

Tool chạy một quy trình cố định: kiểm tra dữ liệu, chia dữ liệu, (hạ mẫu), chạy SR, huấn luyện và đánh giá bộ nhận dạng, kiểm định thống kê, đo latency CPU. Kết quả chính là **một file `report.md` bằng tiếng Anh, trình bày đẹp, đọc được ngay** (mục 2).

Kế hoạch gồm 4 phần:
- **A.** Xây dựng tool (tuần 1–7)
- **B.** Kiểm thử và kiểm chứng (viết song song với A; demo và người dùng thử ở tuần 9–10)
- **C.** Release mã nguồn và README (tuần 8 bản beta, tuần 11 bản chính thức)
- **D.** Viết bài SoftwareX (tuần 12–14)

---

## 1. Quy định phạm vi v0.1.0 (đã chốt)

### 1.1. Bảng chốt

| Hạng mục | Quy định |
|---|---|
| Chia dữ liệu | Người dùng khai báo trong config: lấy từ cột `split` của `labels.csv`, hoặc chia theo tỉ lệ train/val/test do người dùng nhập (mặc định 0.7/0.1/0.2) với seed riêng cho phép chia (mục 1.2, 2.4) |
| Loại bài toán | **Chỉ nhận dạng tập đóng (closed-set identification):** mỗi lớp là một danh tính (người) hoặc một lớp đối tượng (loài, giống); mọi lớp có mặt ở cả train, val và test. Phân loại thuộc tính (ví dụ giới tính) và xác thực (verification) **không** thuộc phạm vi v0.1.0 |
| Chế độ dữ liệu | `synthetic`: ảnh là HR, tool hạ mẫu. `native-lr`: ảnh là LR thật, tool không hạ mẫu |
| Hạ mẫu (`synthetic`) | Theo **một hệ số** `scale` ∈ {2, 3, 4} mỗi lần chạy, mặc định 4; bicubic kiểu MATLAB `imresize` (có antialias); ảnh HR được cắt mép cho chia hết cho `scale` (mod-crop) |
| Hệ số SR | Đọc từ file trọng số. **Mọi SR trong một lần chạy phải có hệ số bằng `scale`**; không khớp thì dừng và báo lỗi |
| Đưa SR vào | 3 cách, mỗi cách có hướng dẫn từng bước và ví dụ chạy được (mục 1.6): (1) file `.pth` do người dùng tự tải, nạp qua spandrel; (2) file Python chứa class mô hình của người dùng (`module`), dùng khi spandrel không nhận ra kiến trúc; (3) thư mục ảnh SR có sẵn, dùng cho mọi mô hình khác |
| Trọng số | Người dùng tự tải. Tool ghi SHA-256 của mọi file vào fingerprint và report. README có bảng link tải chính thức kèm SHA-256 của 4 file trọng số kiểm chứng |
| SR kiểm chứng (5) | Bicubic (baseline); SwinIR-M ×4 classical (train với suy giảm bicubic, DIV2K); **SwinIR-M ×4 real-world** (cùng kiến trúc, train với suy giảm thực tế kiểu BSRGAN); Real-ESRGAN ×4 (`RealESRGAN_x4plus`, suy giảm thực tế); SPAN ×4 (suy giảm bicubic). Cặp SwinIR classical và real-world tách được ảnh hưởng của **kiến trúc** khỏi ảnh hưởng của **loại suy giảm lúc train** (mục 1.7, M2) |
| Nhận dạng kiểm chứng (3) | ResNet-18, MobileNetV3-Small, ConvNeXt-Tiny (timm, pretrained ImageNet, fine-tune). Mọi tên timm khác chạy được nhưng có cảnh báo `experimental` |
| Chuẩn hóa kích thước | Sau SR: letterbox (giữ tỉ lệ, thêm viền) về kích thước đầu vào bộ nhận dạng, mặc định 224×224; giống hệt cho mọi SR |
| Huấn luyện bộ nhận dạng | Khóa `protocol` (mục 1.3, quy tắc 8). **Mặc định `matched`:** với mỗi mô hình SR (kể cả bicubic), ảnh train, val và test đều đi qua **cùng** mô hình SR đó; mỗi (SR, backbone, seed) có một bộ nhận dạng riêng, train trên train+val đã qua SR và test trên test đã qua SR. Tùy chọn `fixed_recognizer`: một bộ nhận dạng cho mỗi (backbone, seed), train trên ảnh HR (`synthetic`) hoặc ảnh LR phóng to bicubic (`native-lr`), chỉ ảnh test đi qua SR |
| Ảnh so sánh trước/sau SR | Với một số ảnh test chọn theo quy tắc cố định, tool xuất **một file PNG gộp** gồm ảnh trước SR (LR) và sau SR của mọi mô hình (kèm bicubic và HR nếu có), mỗi ô có chú thích tiếng Anh: tên phương pháp, nhãn dự đoán đúng/sai, PSNR/SSIM của ảnh đó (mục 2.5) |
| Metric | **Nhận dạng:** Rank-1 accuracy (metric chính, dùng cho kiểm định thống kê và kết luận), Rank-5 accuracy và đường CMC (Rank-1 đến Rank-10; Rank-k lớn hơn số lớp ghi `n/a`), macro precision, macro recall, macro F1-score. **Chất lượng ảnh** (chỉ ở chế độ `synthetic`): PSNR và SSIM (kênh Y, cắt viền `scale` px). Bộ metric cố định, không cấu hình |
| Thống kê | 3 seed (0, 1, 2), báo mean ± sd. So sánh mỗi SR với bicubic: CI 95% bootstrap theo ảnh test và kiểm định hoán vị cặp (paired permutation), 10.000 lần lặp; hiệu chỉnh Holm theo từng backbone |
| Theo kích thước ảnh | 4 nhóm cố định theo cạnh ngắn của ảnh đưa vào SR: `<32`, `32–63`, `64–127`, `≥128` px; nhóm có dưới 50 ảnh test ghi `insufficient data` |
| Latency | CPU, PyTorch, batch 1, 4 luồng, đầu vào LR 64×64 (cấu hình được); 10 lần khởi động + 100 lần đo; median và p95 cho SR, bộ nhận dạng và cả chuỗi |
| CLI | Đúng 3 lệnh: `init`, `run`, `reproduce` |
| Đầu ra | Thư mục chạy chứa `report.md` (đọc đầu tiên) và các file máy đọc được (mục 2.1) |
| Tái lập | `fingerprint.yaml` cho mỗi lần chạy; `reproduce <demo>` ở hai mức: `--eval-only` (dùng checkpoint bộ nhận dạng đã phát hành, không train) và train lại đầy đủ; so với giá trị chuẩn trong dung sai, mã thoát 0/2/3 |
| Ngôn ngữ | Chỉ tiếng Anh cho mọi thứ thuộc phần mềm và bài báo (mục 1.4) |

### 1.2. Format dataset quy định (người dùng tự chuẩn bị)

Tool **chỉ chấp nhận đúng format này**. Tool không tự đoán cấu trúc thư mục, không có adapter. Người dùng tự chuyển dataset của mình sang format này; README có đoạn code mẫu để chuyển từ các kiểu phổ biến.

```
data/<dataset_name>/
├── images/        # all images; any sub-folder structure is allowed
└── labels.csv     # exactly one row per image
```

**`labels.csv`:**

| Cột | Bắt buộc | Quy định |
|---|---|---|
| `path` | Có | Đường dẫn tương đối tính từ `images/`, dùng dấu `/`, không trùng lặp |
| `label` | Có | Nhãn cần nhận dạng, kiểu chuỗi |
| `split` | Không | `train`, `val` hoặc `test` |

**Quy định chi tiết:**
- Định dạng ảnh: `.jpg`, `.jpeg`, `.png`, `.bmp`. Ảnh xám được chuyển sang 3 kênh RGB; việc chuyển đổi được ghi vào report.
**Quy định chia train/val/test** (người dùng khai báo trong khối `split` của config, mục 2.4):
- `split.source` chọn nguồn của phép chia:
  - `auto` (mặc định): dùng cột `split` nếu `labels.csv` có cột này, nếu không thì chia theo `split.ratios`.
  - `column`: bắt buộc dùng cột `split`; thiếu cột thì dừng và báo lỗi.
  - `ratios`: bỏ qua cột `split` (nếu có) và chia theo `split.ratios`.
- Khi dùng cột `split`: phải có ít nhất `train` và `test`. Nếu không có dòng `val` nào, tool chuyển một phần `train` sang `val` theo `split.val_from_train` (mặc định 0.1, phân tầng theo nhãn, dùng `split.seed`).
- Khi chia theo tỉ lệ: `split.ratios` gồm ba giá trị `train`, `val`, `test`, mỗi giá trị lớn hơn 0 và nhỏ hơn 1, tổng bằng 1.0 (sai số cho phép 1e-6); mặc định 0.7 / 0.1 / 0.2. Phép chia dùng `split.seed` (mặc định 0), tách biệt với seed của bộ nhận dạng, nên mọi seed train dùng chung một phép chia.
  - Chia phân tầng **trong từng lớp** (từng danh tính). Với lớp có *n* ảnh: số ảnh test = max(1, làm tròn *n* × test), số ảnh val = max(1, làm tròn *n* × val), phần còn lại là train và phải có ít nhất 1 ảnh. Lớp nào không đáp ứng được thì tool dừng và liệt kê các lớp đó cùng số ảnh tối thiểu cần có.
- Report luôn in **tỉ lệ khai báo và số ảnh thực tế** của từng tập.
- Phép chia được lưu thành `split.csv` trong thư mục chạy và dùng lại ở các lần chạy sau có cùng dữ liệu và cùng khai báo `split`; đổi khai báo thì tạo phép chia mới và cảnh báo.
- Chế độ `synthetic`: ảnh trong `images/` là HR. Chế độ `native-lr`: ảnh là LR thật.
- Thư mục ảnh SR có sẵn (cách đưa SR thứ 3): mỗi ảnh SR có **cùng `path`** với ảnh gốc tương ứng, định dạng PNG. Với `protocol: matched`, thư mục phải có ảnh SR của **cả ba tập train, val và test**; với `fixed_recognizer`, chỉ cần tập test. Ở chế độ `synthetic`, tool luôn lưu ảnh LR vào `lr/train/`, `lr/val/`, `lr/test/` trong thư mục chạy, để người dùng chạy SR bên ngoài trên đúng các ảnh đó rồi đưa kết quả vào lần chạy sau.

Lệnh `init` **chỉ kiểm tra** format: thiếu cột, `path` không tồn tại, ảnh không đọc được, lớp quá ít ảnh để chia theo tỉ lệ đã khai báo, cùng một ảnh (trùng nội dung theo SHA-256, dù khác tên file) nằm ở hai tập khác nhau. Sai thì dừng, báo lỗi theo số dòng của `labels.csv` và chỉ tới mục "Preparing your dataset" trong README.

### 1.3. Các quy tắc phương pháp (bắt buộc, không cấu hình được)

1. **Cùng tập test, cùng đường xử lý:** mọi SR (kể cả bicubic) được đánh giá trên đúng một tập ảnh test, và đi qua cùng bước letterbox.
2. **Chia dữ liệu đúng cho nhận dạng tập đóng:** mọi danh tính có ở cả train, val và test; không ảnh nào (kể cả ảnh trùng nội dung khác tên) nằm ở hai tập.
3. **Bộ nhận dạng không bao giờ thấy ảnh test khi train hay chọn checkpoint.** Checkpoint tốt nhất được chọn trên `val`.
4. **Không tự quyết thay người dùng:** giá trị do `init` gợi ý (chế độ dữ liệu) được đánh dấu `[CHECK]`; `run` từ chối chạy khi config còn `[CHECK]`.
5. **Không tính số liệu không chuẩn:** PSNR/SSIM chỉ tính ở chế độ `synthetic`; ở `native-lr` ghi `n/a (no HR reference)`.
6. **Ghi rõ giới hạn của `protocol: fixed_recognizer`:** bộ nhận dạng không được train trên ảnh đã qua SR, nên các SR bị lệch miền dữ liệu so với lúc train (ở `native-lr`, baseline bicubic còn ở đúng miền trong khi các SR thì không). Khi dùng protocol này, report luôn in câu cảnh báo. Câu hỏi protocol này trả lời là: *"Gắn thêm SR trước một bộ nhận dạng có sẵn thì có giúp không?"* Protocol mặc định `matched` không có giới hạn này.
7. **Ghi rõ nguồn trọng số:** report in tên file và SHA-256 của từng SR, kèm cảnh báo rằng trọng số train trên ảnh tự nhiên (DIV2K) có thể lệch miền với dữ liệu của người dùng.

8. **Train, val và test đi qua cùng một đường xử lý (`protocol: matched`, mặc định):** với mỗi mô hình SR, ảnh train, val và test được xử lý giống hệt nhau: (`synthetic`: mod-crop, hạ mẫu ×`scale`) → SR → letterbox. Bộ nhận dạng của mô hình SR nào thì chỉ được train và chọn checkpoint trên ảnh đã qua đúng mô hình SR đó, và chỉ được test trên ảnh test đã qua đúng mô hình SR đó. Baseline bicubic đi qua cùng quy trình với bicubic ở vị trí của SR. Hàng `HR (upper bound)` (chỉ ở `synthetic`) được train, chọn checkpoint và test trên ảnh HR. Câu hỏi protocol này trả lời là: *"Nếu xây cả hệ thống (train và triển khai) với SR này thì nhận dạng có tốt hơn không?"*
9. **So sánh cặp vẫn hợp lệ:** dù mỗi SR có bộ nhận dạng riêng, mọi SR được đánh giá trên cùng các ảnh test gốc và cùng các seed, nên kiểm định cặp theo ảnh (và ghép cặp theo seed) vẫn áp dụng như mục cài đặt thống kê dưới đây.

**Quy tắc kết luận tự động** (dùng trong report):

| Nhãn | Điều kiện |
|---|---|
| `▲ significant gain` | Δ > 0, CI 95% không chứa 0, p (Holm) < 0.05 |
| `▼ significant harm` | Δ < 0, CI 95% không chứa 0, p (Holm) < 0.05 |
| `● no difference` | Các trường hợp còn lại |
| `insufficient data` | Nhóm kích thước có dưới 50 ảnh test (không kiểm định) |

**Metric chính và metric phụ:** accuracy là metric chính được khai báo trước; kiểm định thống kê, CI và nhãn kết luận chỉ dùng accuracy, để không phải hiệu chỉnh thêm cho nhiều metric. Macro precision, macro recall, macro F1-score (trung bình không trọng số qua các lớp; lớp không được dự đoán lần nào có precision bằng 0, theo quy ước `zero_division=0` của scikit-learn), PSNR và SSIM được báo cáo mô tả (mean ± sd qua seed).

**Cài đặt thống kê:**
- Với mỗi backbone và mỗi SR, tính độ đúng của từng ảnh test ở mỗi seed, rồi lấy trung bình qua 3 seed để được điểm của từng ảnh.
- Δ = trung bình điểm ảnh của SR trừ của bicubic, tính bằng điểm phần trăm (pp).
- CI 95%: bootstrap lấy mẫu lại **ảnh test** (percentile), 10.000 lần, seed cố định.
- p: kiểm định hoán vị cặp dạng đổi dấu (sign-flip) trên hiệu điểm từng ảnh, 10.000 lần, hai phía.
- Holm: trên các so sánh (SR − bicubic) của cùng một backbone.

### 1.4. Quy định ngôn ngữ (bắt buộc)

Mọi thứ thuộc về phần mềm và bài báo **chỉ dùng tiếng Anh, không dùng tiếng Việt**:
- Mã nguồn: tên biến, tên hàm, comment, docstring.
- CLI: log, cảnh báo, thông báo lỗi; nhãn trong file config sinh ra (`[CHECK]`).
- Config mẫu và comment trong config.
- Mọi đầu ra: `report.md`, tên cột CSV, nhãn kết luận, bảng LaTeX.
- Hình ảnh: tiêu đề, nhãn trục, legend, chữ trong sơ đồ, ảnh chụp màn hình.
- README, `docs/`, `CHANGELOG.md`, `CITATION.cff`, commit message, issue, pull request.
- Bài báo SoftwareX cùng toàn bộ hình và bảng.

Tài liệu kế hoạch này là tài liệu nội bộ nên viết tiếng Việt; mọi ví dụ trích từ phần mềm trong tài liệu giữ nguyên tiếng Anh như khi phát hành. CI có bước quét toàn repo và báo lỗi khi phát hiện ký tự tiếng Việt có dấu (B5.3).

### 1.5. Cấu trúc thư mục làm việc của người dùng (ghi trong README)

Mọi file người dùng tự chuẩn bị hoặc tự tải về được đặt trong **một thư mục dự án** theo cấu trúc chuẩn dưới đây. README có mục "Project layout" trình bày đúng cây thư mục này. Mọi ví dụ trong README, config mẫu và các demo `reproduce` đều dùng cấu trúc này.

```
my_project/                      # project folder; run every command from here
├── sr4rec.yaml                  # written by `sr4rec init`, edited by the user
├── data/                        # datasets prepared by the user
│   └── <dataset_name>/
│       ├── images/              # all images (any sub-folder structure)
│       └── labels.csv           # one row per image (see "Preparing your dataset")
├── weights/                     # SR weight files downloaded or trained by the user
│   ├── RealESRGAN_x4plus.pth
│   ├── 001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth
│   ├── 003_realSR_BSRGAN_DFO_s64w8_SwinIR-M_x4_GAN.pth
│   └── spanx4_ch48.pth
├── sr_images/                   # optional: SR outputs produced by external tools
│   └── <method_name>/           # same relative paths as the test images
└── runs/                        # created by SR4Rec; never edit by hand
    ├── .cache/                  # cached SR outputs and recognizer checkpoints
    └── <run_name>/              # one folder per run (report.md, CSV files, plots, ...)
```

**Quy định:**
- Mọi đường dẫn trong `sr4rec.yaml` là **đường dẫn tương đối tính từ thư mục chứa `sr4rec.yaml`** (hoặc đường dẫn tuyệt đối). Nhờ vậy cả thư mục dự án chuyển sang máy khác vẫn chạy được.
- `sr4rec init data/<dataset_name>` ghi `sr4rec.yaml` vào **thư mục hiện tại** và điền sẵn `dataset: data/<dataset_name>`. Nếu `sr4rec.yaml` đã tồn tại, `init` không ghi đè trừ khi có cờ `--force`.
- `weights/` và `sr_images/` là vị trí **khuyến nghị**: tool đọc đúng đường dẫn khai báo trong config, không tự tìm file. Tool không tự tải trọng số SR.
- `runs/` do tool tạo, vị trí đổi được bằng `runtime.output_dir`; cache nằm ở `runs/.cache/` và đổi được bằng `runtime.cache_dir`. Xóa `runs/.cache/` chỉ làm lần chạy sau chậm hơn, không làm sai kết quả.
- Trọng số pretrained ImageNet của các backbone do timm **tự tải** ở lần chạy đầu, lưu trong cache của Hugging Face (mặc định `~/.cache/huggingface/`, đổi bằng biến môi trường `HF_HOME`). Máy không có mạng thì cần tải trước; README có hướng dẫn.
- Dataset của các demo trong bài báo được chuẩn bị bằng `python scripts/prepare_<dataset>.py --out data/<dataset>`; `sr4rec reproduce <demo>` mặc định tìm dữ liệu trong `data/` và trọng số trong `weights/` của thư mục hiện tại, đổi được bằng `--data-root` và `--weights-root`.

### 1.6. Tài nguyên mẫu đi kèm bản phát hành (bắt buộc)

Bản phát hành phải có sẵn **dataset mẫu, file config mẫu, mô hình SR mẫu và hướng dẫn từng bước** cho mọi cách đưa dữ liệu và mô hình SR vào tool. Mọi ví dụ đều **chạy được ngay trên CPU** sau khi cài đặt, và CI chạy lại toàn bộ ở mỗi lần build (B5.7), nên ví dụ không bao giờ lệch với code.

**Cấu trúc thư mục `examples/` trong repo:**

```
examples/
├── README.md                       # index: which example to open for which need
├── data/                           # small subsets of REAL public datasets (< 15 MB in total)
│   ├── pets_mini/                  # Oxford-IIIT Pet subset: HR images, closed-set recognition of breeds
│   │   ├── images/
│   │   ├── labels.csv
│   │   └── LICENSE.txt             # licence and attribution of the original dataset
│   ├── earvn_mini/                 # EarVN1.0 subset: native low-resolution ears, identity recognition
│   │   ├── images/
│   │   ├── labels.csv
│   │   └── LICENSE.txt
│   └── lfw_mini/                   # faces: NO images in the repo, built locally from the user's LFW copy
│       ├── selection.csv           # chosen file names and their SHA-256
│       ├── labels.csv
│       └── README.md               # download steps, privacy note, terms of the original dataset
├── configs/                        # ready-to-run configs, one feature per file
│   ├── full_reference.yaml         # every key with full comments (same as `sr4rec init` output)
│   ├── 01_quickstart.yaml
│   ├── 02_synthetic_pth.yaml
│   ├── 03_native_lr.yaml
│   ├── 04_fixed_recognizer.yaml
│   ├── 05_split_ratios.yaml
│   ├── 06_sr_module.yaml
│   ├── 07_sr_images.yaml
│   └── 08_faces_lfw.yaml
├── sr_models/                      # custom SR model example (method 2)
│   ├── tiny_espcn.py               # model class following the SR4Rec interface
│   ├── tiny_espcn_x4_pets.pth      # small weights trained on the pets_mini train split only (about 100 KB)
│   └── train_tiny_espcn.py         # script that produced the weights
├── sr_images/                      # external SR output example (method 3)
│   └── make_sr_images.py           # writes SR images with the required names
└── dataset_conversion/             # turning common layouts into images/ + labels.csv
    ├── from_folder_per_label.py
    ├── from_filename_pattern.py
    └── from_annotation_csv.py
```

#### 1.6.1. Dataset mẫu

| Dataset | Dùng để minh họa | Nội dung |
|---|---|---|
Dataset mẫu cho người dùng là **tập con nhỏ của dataset thật, đã công bố**, không phải dữ liệu do script sinh ra. Mỗi tập con có sẵn `labels.csv` theo đúng format 1.2 và file `LICENSE.txt` ghi giấy phép, nguồn và cách trích dẫn dataset gốc.

| Dataset mẫu | Nguồn | Dùng để minh họa | Nội dung |
|---|---|---|---|
| `pets_mini` | Oxford-IIIT Pet (Parkhi et al., CVPR 2012) | `mode: synthetic`, `split.source: column` và `ratios` (lớp là giống thú) | 10 giống chó mèo × 30 ảnh; ảnh được thu nhỏ để cạnh ngắn bằng 256 px (ảnh HR); `labels.csv` có cột `split` lấy từ split chính thức |
| `earvn_mini` | EarVN1.0 (Hoang, Data in Brief 2019) | `mode: native-lr`, nhận dạng danh tính, phân tích theo nhóm kích thước | 20 người (10 nam, 10 nữ) × 20 ảnh, giữ nguyên kích thước gốc (nhiều ảnh nhỏ tự nhiên, có ảnh dưới 25×25 px); `labels.csv` chỉ có `path`, `label` (tool tự chia) |

**Điều kiện giấy phép (kiểm tra và chốt ở A0.5, không được bỏ qua):**
- **EarVN1.0:** trang Mendeley Data của dataset ghi rằng mọi quyền được bảo lưu và việc sử dụng hay phân phối cho mục đích thương mại bị cấm. Vì vậy **chỉ được đóng gói tập con vào repo khi có văn bản cho phép của tác giả dataset**, trong đó ghi rõ phạm vi (số ảnh, mục đích minh họa phần mềm, phi thương mại). Tác giả dataset là V. T. Hoang; xin văn bản này khi gặp thầy ở A0.3.
- **Oxford-IIIT Pet:** cần đọc và lưu lại nguyên văn điều khoản sử dụng trên trang chính thức của dataset trước khi đóng gói; nếu điều khoản yêu cầu chia sẻ cùng giấy phép (share-alike), thư mục `pets_mini/` mang giấy phép đó, tách biệt với giấy phép MIT của mã nguồn.
- **Phương án dự phòng** nếu không được phép đóng gói: repo không chứa ảnh, chỉ chứa danh sách tên file đã chọn (`examples/data/<name>/selection.csv`) và `labels.csv`. Người dùng tự tải dataset gốc từ trang chính thức, rồi chạy `python scripts/make_examples.py --pets <path> --earvn <path>` để dựng lại **đúng** tập con đó (kiểm tra bằng SHA-256 từng ảnh). README ghi rõ các bước này.

**Dữ liệu tổng hợp chỉ dùng nội bộ cho test:** unit test và các bước CI cần chạy nhanh, tất định và không phụ thuộc giấy phép sử dụng một dataset rất nhỏ sinh trong bộ nhớ (`tests/fixtures/`). Dữ liệu này không xuất hiện trong `examples/`, README hay bài báo.

Mỗi `labels.csv` mẫu là **ví dụ chuẩn** để người dùng nhìn vào và làm theo. Trích `examples/data/pets_mini/labels.csv`:
```csv
path,label,split
Abyssinian/Abyssinian_1.jpg,Abyssinian,train
Abyssinian/Abyssinian_10.jpg,Abyssinian,test
beagle/beagle_101.jpg,beagle,train
```

**Ví dụ ảnh khuôn mặt (`lfw_mini`), không đóng gói ảnh:**
- Nguồn: LFW (Labeled Faces in the Wild, Huang et al. 2007). Tài liệu chính thức của LFW không nêu điều khoản giấy phép, và ảnh khuôn mặt là dữ liệu sinh trắc học của người thật. Vì vậy **repo không chứa bất kỳ ảnh khuôn mặt nào**.
- Repo chỉ chứa `selection.csv` (danh sách tên file và SHA-256), `labels.csv`, và `README.md` hướng dẫn. Tập con: những người có **ít nhất 20 ảnh** trong LFW, dùng cho `mode: synthetic`, `task: closed_set`; phép chia được cố định sẵn trong `labels.csv` (cột `split`).
- Người dùng tự tải LFW từ nguồn chính thức, rồi chạy `python scripts/make_examples.py --lfw <path_to_lfw>` để dựng `examples/data/lfw_mini/images/`; script kiểm tra SHA-256 từng ảnh và báo ảnh thiếu hoặc sai.
- README của ví dụ và README chính đều có **lưu ý quyền riêng tư**: ảnh khuôn mặt là dữ liệu sinh trắc học; người dùng phải tuân thủ điều khoản của dataset gốc và quy định về dữ liệu cá nhân nơi họ làm việc; không dùng tool để nhận dạng người ngoài mục đích nghiên cứu.
- **TinyFace** (ảnh mặt độ phân giải thấp tự nhiên, trung bình khoảng 20×16 px) chỉ được giới thiệu trong `docs/preparing_dataset.md` như ví dụ cho `mode: native-lr`, kèm hướng dẫn chuyển sang format 1.2. Không có config mẫu và không có script dựng tập con cho TinyFace; tài liệu ghi rõ trang chính thức không nêu điều khoản sử dụng và người dùng cần liên hệ tác giả dataset trước khi dùng.
- Ví dụ khuôn mặt **không chạy trong CI** (CI không tải được LFW); được kiểm tra thủ công trước mỗi release (C4.6).
- Bài báo SoftwareX **không dùng ảnh khuôn mặt** trong hình minh họa; chỉ nhắc ví dụ này như một khả năng áp dụng.

Trích `examples/data/earvn_mini/labels.csv` (mỗi nhãn là một người):
```csv
path,label
001/0001.jpg,001
001/0002.jpg,001
120/0001.jpg,120
```

#### 1.6.2. File config mẫu

| File | Minh họa | Ghi chú |
|---|---|---|
| `full_reference.yaml` | Mọi khóa với comment đầy đủ (mục 2.4) | Giống hệt đầu ra của `sr4rec init` |
| `01_quickstart.yaml` | Quy trình tối thiểu | `pets_mini`, ×4, SR `tiny_espcn` (cách 2), 1 backbone, 1 seed, 3 epoch, CPU; dùng cho `sr4rec reproduce quickstart`, chạy khoảng 5 phút |
| `02_synthetic_pth.yaml` | Cách 1: file `.pth` | 4 file trọng số kiểm chứng; cần tải trọng số vào `weights/` trước (hướng dẫn trong comment đầu file) |
| `03_native_lr.yaml` | `mode: native-lr` | `earvn_mini`; report có mục theo nhóm kích thước |
| `04_fixed_recognizer.yaml` | `protocol: fixed_recognizer` (sàng lọc nhanh) | `pets_mini`; so với `02` để thấy khác biệt giữa hai protocol |
| `05_split_ratios.yaml` | Tự nhập tỉ lệ chia | `split.source: ratios`, tỉ lệ 0.8 / 0.1 / 0.1 |
| `06_sr_module.yaml` | Cách 2: file Python chứa mô hình | Dùng `examples/sr_models/tiny_espcn.py` |
| `07_sr_images.yaml` | Cách 3: thư mục ảnh SR có sẵn | Dùng ảnh do `examples/sr_images/make_sr_images.py` tạo |
| `08_faces_lfw.yaml` | Ảnh khuôn mặt, `synthetic`, nhận dạng danh tính | Dùng `lfw_mini`; cần chạy `scripts/make_examples.py --lfw <path>` trước (hướng dẫn trong comment đầu file) |

Mỗi file mẫu có comment ở đầu nêu: mục đích, lệnh chạy, thời gian chạy dự kiến, và cần chuẩn bị gì trước. Ví dụ:
```yaml
# Example 06: plug in your own SR model as a Python class (method 2).
# Run from the repository root:
#   sr4rec run examples/configs/06_sr_module.yaml
# Expected time: about 5 minutes on a laptop CPU.
# Nothing to download: the model code and its weights are in examples/sr_models/.
```

#### 1.6.3. Ba cách đưa mô hình SR vào, có hướng dẫn từng bước

README có mục "Adding SR models" bắt đầu bằng bảng chọn cách, sau đó là hướng dẫn từng bước của từng cách. Bản đầy đủ nằm trong `docs/adding_sr_models.md`.

| Tôi có… | Dùng cách | Tool đo được latency? |
|---|---|---|
| File `.pth` / `.safetensors` của một kiến trúc spandrel hỗ trợ | 1. `weights` | Có |
| Code PyTorch của mô hình (kèm hoặc không kèm file trọng số) | 2. `module` | Có |
| Chỉ có ảnh kết quả, hoặc mô hình không phải PyTorch | 3. `images` | Không |

Trước khi chạy thật, người dùng luôn kiểm tra bằng `sr4rec run <config> --dry-run`: tool kiểm tra config và dataset, nạp mọi mô hình SR, chạy mỗi mô hình trên 2 ảnh test, kiểm tra hệ số và kích thước đầu ra, in bảng tóm tắt rồi dừng, không train.

```
$ sr4rec run sr4rec.yaml --dry-run
Config              OK
Dataset             OK  (300 images, 10 classes)
SR models
  bicubic           OK  x4  built-in baseline
  realesrgan        OK  x4  weights  ESRGAN (spandrel)  sha256 4fa0d38...
  my_sr             OK  x4  module   examples/sr_models/tiny_espcn.py:TinyESPCN
  colleague_sr      OK  x4  images   60/60 test images found
Plan                5 image pipelines (bicubic + 4 SR) + HR, 3 backbones, 3 seeds
                    = 54 recognizer trainings, 3,000 SR images to compute
Estimated time      about 15 h on NVIDIA RTX 3090 (from a timed mini-epoch)
Dry run passed. Start the real run with: sr4rec run sr4rec.yaml
```

**Cách 1: file trọng số `.pth` (spandrel)**

1. Tải file trọng số từ trang chính thức của tác giả (README có bảng link và SHA-256 cho 4 file trọng số kiểm chứng) và đặt vào `weights/`.
2. Khai báo trong `sr4rec.yaml`:
   ```yaml
   sr:
     - name: swinir
       weights: weights/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth
   ```
3. Chạy `sr4rec run sr4rec.yaml --dry-run`. Nếu dòng của mô hình báo `OK`, chạy thật.
4. Nếu báo `spandrel could not detect the architecture`, chuyển sang cách 2 (có code PyTorch) hoặc cách 3.

**Cách 2: file Python chứa class mô hình (`module`)**

1. Viết (hoặc chép từ repo của tác giả) một class PyTorch theo **giao diện bắt buộc** dưới đây, đặt vào `sr_models/<file>.py` trong thư mục dự án.
2. Khai báo trong `sr4rec.yaml`: `module: <file>.py:<ClassName>`; `weights` là tùy chọn và được truyền vào hàm khởi tạo.
   ```yaml
   sr:
     - name: my_sr
       module: sr_models/tiny_espcn.py:TinyESPCN
       weights: weights/tiny_espcn_x4.pth    # optional; passed to __init__(weights=...)
   ```
3. Chạy `--dry-run`. Tool kiểm tra: file và class tồn tại; class là `torch.nn.Module`; có thuộc tính `scale` kiểu số nguyên bằng `scale` trong config; với đầu vào 2×3×16×16, đầu ra đúng kích thước 2×3×(16·scale)×(16·scale), kiểu float, không có NaN.
4. Nếu class cần thư viện của repo gốc, thêm đường dẫn repo vào đầu file (ví dụ trong mẫu) hoặc cài repo đó bằng `pip install -e`.

Giao diện bắt buộc (mẫu `examples/sr_models/tiny_espcn.py`):
```python
"""Minimal SR model that follows the SR4Rec module interface.

Interface required by SR4Rec:
  * the class is a torch.nn.Module;
  * it has an integer class attribute `scale` (the upscaling factor);
  * __init__ accepts one optional argument `weights` (path or None);
  * forward(x) receives a float32 RGB tensor in [0, 1] with shape (N, 3, H, W)
    and returns a float32 RGB tensor with shape (N, 3, H * scale, W * scale).
SR4Rec calls model.eval(), runs forward() under torch.no_grad(), moves the model
to the configured device, and clamps the output to [0, 1].
"""
from typing import Optional

import torch
from torch import nn


class TinyESPCN(nn.Module):
    scale = 4

    def __init__(self, weights: Optional[str] = None):
        super().__init__()
        self.body = nn.Sequential(
            nn.Conv2d(3, 32, 5, padding=2), nn.ReLU(inplace=True),
            nn.Conv2d(32, 32, 3, padding=1), nn.ReLU(inplace=True),
            nn.Conv2d(32, 3 * self.scale ** 2, 3, padding=1),
            nn.PixelShuffle(self.scale),
        )
        if weights is not None:
            state = torch.load(weights, map_location="cpu", weights_only=True)
            self.load_state_dict(state)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.body(x)
```

Lưu ý an toàn ghi trong README: cách 2 chạy code Python của người dùng, nên chỉ dùng file mình tin tưởng; SHA-256 của file `.py` và file trọng số được ghi vào fingerprint.

**Cách 3: thư mục ảnh SR có sẵn (`images`)**

1. Chạy tool một lần với các mô hình khác (hoặc chỉ bicubic). Ở chế độ `synthetic`, ảnh LR nằm trong `runs/<run_name>/lr/train/`, `lr/val/`, `lr/test/`; ở chế độ `native-lr`, ảnh LR là chính các ảnh trong `data/<dataset>/images/` (tập của từng ảnh ghi trong `runs/<run_name>/split.csv`). Với `protocol: matched` cần chạy SR trên cả ba tập; với `fixed_recognizer` chỉ cần tập test.
2. Chạy mô hình SR bên ngoài trên đúng các ảnh đó, lưu kết quả dạng PNG vào `sr_images/<name>/` với **cùng đường dẫn tương đối**, chỉ đổi đuôi thành `.png`. Ví dụ: `lr/test/Abyssinian/Abyssinian_10.png` → `sr_images/my_method/Abyssinian/Abyssinian_10.png` (tương tự cho `lr/train/` và `lr/val/`; cả ba tập ghi chung vào một thư mục `sr_images/my_method/` vì `path` không trùng nhau).
3. Khai báo:
   ```yaml
   sr:
     - name: my_method
       images: sr_images/my_method/
   ```
4. Chạy `--dry-run`. Tool báo file thiếu, file thừa, và ảnh sai kích thước (phải đúng `scale` × kích thước LR).

Script mẫu `examples/sr_images/make_sr_images.py` minh họa đúng quy ước đặt tên (dùng Lanczos của PIL thay cho một mô hình SR thật).

#### 1.6.4. Hướng dẫn chuẩn bị dataset

`docs/preparing_dataset.md` và mục "Preparing your dataset" của README trình bày:
1. Đặc tả `images/` + `labels.csv` (mục 1.2) kèm các file mẫu ở 1.6.1.
2. Ba script chuyển đổi trong `examples/dataset_conversion/`, mỗi script chạy được trên một thư mục mẫu kèm theo:
   - `from_folder_per_label.py`: `images/<label>/*.jpg` → `labels.csv`.
   - `from_filename_pattern.py`: nhãn nằm trong tên file (ví dụ `017_s1_03.jpg`).
   - `from_annotation_csv.py`: nhãn nằm trong một file chú thích có tên cột khác.
3. Cách chọn `mode`, `protocol` và khai báo khối `split`.
4. Bảng các lỗi thường gặp khi `sr4rec init` báo sai format và cách sửa.

### 1.7. Xử lý các góp ý dự kiến của reviewer (M1–M4, m1–m5)

Bảng này ghi lại cách kế hoạch xử lý từng góp ý mà một reviewer SoftwareX nhiều khả năng sẽ đưa ra. Mỗi dòng dẫn tới nơi xử lý trong kế hoạch.

| # | Góp ý dự kiến | Cách xử lý | Ở đâu trong kế hoạch |
|---|---|---|---|
| M1 | "Tool chỉ là lớp bọc spandrel + timm + SciPy?" | Chứng minh bằng số liệu rằng các quy tắc tool áp đặt làm đổi kết luận: demo D5 (protocol `matched` so với `fixed_recognizer`; độ dao động khi đổi phép chia so với khác biệt giữa các SR; xếp hạng theo PSNR/SSIM so với theo Rank-1). Bảng 2 ghi như EmbedKD: mọi thành phần đều có thể dựng trong framework khác, đóng góp là quy trình đã kiểm chứng. Một đoạn giải thích vì sao không làm plugin cho BasicSR (BasicSR là framework huấn luyện SR, không có train bộ nhận dạng, protocol chia dữ liệu và kiểm định thống kê) | B7 (D5), D2b, D3 |
| M2 | "Real-ESRGAN bị so trên ảnh LR bicubic sạch là không công bằng" | Thêm SwinIR real-world vào danh sách kiểm chứng: cặp SwinIR classical và real-world cùng kiến trúc, khác loại suy giảm lúc train. Report và bài ghi rõ loại suy giảm lúc train của từng SR (cột `Trained for`), và in cảnh báo khi SR train cho suy giảm thực tế được chạy trên LR bicubic. D3 (ảnh nhỏ tự nhiên) là bằng chứng chính; D1 là thí nghiệm có kiểm soát | 1.1, 2.3, B7 (D1, D3), D2b, D3 |
| M3 | "Chỉ phân loại, không có protocol sinh trắc học" | Phạm vi được nêu đúng là nhận dạng tập đóng (closed-set identification), protocol chuẩn trong nhận dạng tai. Báo cáo Rank-1 (metric chính), Rank-5 và đường CMC. Mục hạn chế nói rõ không có xác thực và tập mở; roadmap có sẵn | 1.1, A6.2, 2.3, D2b, mục 6 |
| M4 | "Chưa có bằng chứng tác động" | Dùng chính tool cho các nghiên cứu của nhóm (bài NCA, EarSR) và ghi vào mục Impact khi các bài đó được chấp nhận hoặc có trên arXiv. Phát hành beta sớm (tuần 8) trên PyPI và GitHub, giới thiệu với cộng đồng. Đo công sức tiết kiệm: cùng một nhiệm vụ làm bằng script tự viết so với bằng SR4Rec (số dòng code, số file, thời gian đến kết quả đầu tiên). Người dùng thử thật (B6) để sau | Lịch tuần 10, D2b |
| m1 | "3 seed là ít" | Đơn vị kiểm định là ảnh test (hàng trăm đến hàng nghìn ảnh); seed chỉ đo độ dao động. Report có cột `Same sign` (số seed có Δ cùng dấu). Config cho phép đến 10 seed | 1.3, A6.4, 2.3 |
| m2 | "Protocol `matched` tốn kém" | `--dry-run` in số lần train dự kiến và ước tính thời gian. README gợi ý quy trình hai bước: `fixed_recognizer` để sàng lọc nhanh, `matched` cho các SR được chọn. Bài báo có GPU-giờ thực tế của từng demo (Bảng 5) | A7.6, C2, D3 |
| m3 | "Siêu tham số cố định có thể thiên vị" | Nêu rõ đây là lựa chọn có chủ đích để công bằng. Demo D6 kiểm tra độ nhạy (learning rate ×0.3 và ×3), kết quả ở Phụ lục C | B7 (D6), D2b |
| m4 | "Giấy phép dataset, checkpoint và quyền riêng tư" | `DATA_AND_MODEL_LICENSES.md` liệt kê giấy phép, nguồn và trích dẫn của mọi dataset, trọng số, checkpoint; không đóng gói ảnh khuôn mặt; checkpoint kế thừa điều khoản của dataset | 1.6.1, C1, C4.7, C4.8 |
| m5 | "Tính bền vững của dự án" | `CONTRIBUTING.md` (gồm tiêu chuẩn để một SR hoặc backbone vào danh sách kiểm chứng), `CODE_OF_CONDUCT.md`, mẫu issue và PR, chính sách phiên bản, badge CI và độ phủ test; mục Impact có đoạn về bảo trì | C1, C4.1, C4.8, D2b |

### 1.8. Các điểm kỹ thuật phát hiện khi rà soát lại toàn bộ kế hoạch

1. **Dataset cho chế độ `synthetic` phải thực sự là ảnh HR.** Phần lớn ảnh EarVN1.0 nhỏ hơn 128 px, nên EarVN1.0 **không** dùng cho chế độ `synthetic` (hạ mẫu ×4 một ảnh 25 px chỉ còn khoảng 6 px, và lọc theo kích thước sẽ loại gần hết dataset). Quyết định: **D1 dùng LFW** (nhận dạng danh tính khuôn mặt, những người có từ 20 ảnh trở lên, ảnh 250×250 px, LR ×4 khoảng 62 px); **D3 dùng toàn bộ EarVN1.0 ở chế độ `native-lr`** và là bằng chứng chính. Ảnh khuôn mặt không được đóng gói và không xuất hiện trong hình của bài; Hình 4 (định tính) lấy từ D3. Checkpoint train trên LFW chỉ phát hành nếu điều khoản của LFW cho phép; nếu không, `--eval-only` của D1 được ghi là không khả dụng.
2. **Kích thước đầu vào mà mô hình SR yêu cầu.** Một số kiến trúc (ví dụ SwinIR với cửa sổ 8×8) cần kích thước ảnh vào là bội số của một số nhất định; ảnh tai nhỏ tự nhiên thường không thỏa. Tool đệm ảnh (reflect padding) tới bội số cần thiết, chạy SR, rồi cắt lại đúng kích thước `scale` × kích thước gốc. Yêu cầu kích thước lấy từ spandrel (với cách 1) hoặc từ thuộc tính tùy chọn `size_multiple` của class (với cách 2). Xem A4.1.
3. **Hiệu chỉnh đa so sánh theo từng backbone.** Holm được áp dụng trên các so sánh (SR − bicubic) của cùng một backbone, không gộp qua các backbone. Đây là lựa chọn có chủ đích (mỗi backbone là một câu hỏi riêng), được ghi trong `docs/methods.md` và trong bài.
4. **Giới hạn số từ.** Có 6 demo nên dễ vượt 4000 từ. Phần chính chỉ trình bày D3, D1, D2 và D4; D5 và D6 mỗi demo 2–3 câu trong phần chính, chi tiết ở Phụ lục C. Đếm từ bằng `texcount` từ bản nháp đầu tiên.
5. **Cần kiểm tra ở A0.4:** spandrel nạp được bản SwinIR real-world (bộ phóng to khác bản classical), ngoài 3 file đã có.
6. **Dung lượng checkpoint** của `--eval-only` với protocol `matched` khoảng 10–15 GB (Zenodo cho phép 50 GB mỗi bản ghi). Nếu cần giảm, phát hành đủ checkpoint cho D2 và D3, còn D1 chỉ phát hành cho 2 backbone nhỏ.

---

## 2. Đặc tả đầu ra và `report.md`

### 2.1. Thư mục kết quả

```
runs/<run_name>/
├── report.md           # human-readable report, read this first
├── plots/
│   ├── accuracy_by_size.png
│   ├── cmc.png                  # CMC curves (Rank-1 to Rank-10)
│   └── quality_vs_accuracy.png  # PSNR and SSIM vs accuracy, synthetic mode only
├── cmc.csv             # Rank-1 ... Rank-10 per backbone x SR x seed
├── metrics.csv         # Rank-1, Rank-5, macro precision, macro recall, macro F1, PSNR, SSIM
│                       # per backbone x SR x seed (and per size bin)
├── stats.csv           # delta vs bicubic, 95% CI, raw p, Holm-adjusted p, verdict
├── predictions.csv     # per-image predictions for every backbone x SR x seed
├── latency.csv         # CPU latency (median, p95) for SR, recognizer and full pipeline
├── table.tex           # main results table (LaTeX, booktabs)
├── split.csv           # the frozen train/val/test split
├── comparisons/        # before/after-SR panels, one PNG per selected test image (section 2.5)
│   └── index.csv       # which images were selected and why
├── lr/                 # LR images of train/, val/, test/ (synthetic mode), for running external SR
├── sr4rec.yaml         # the exact configuration used
└── fingerprint.yaml    # environment, versions, data and weight hashes
```

Màn hình khi chạy xong chỉ in 4–5 dòng tóm tắt và đường dẫn tới `report.md`.

### 2.2. Tiêu chuẩn trình bày của `report.md`

- Viết bằng tiếng Anh, Markdown chuẩn GitHub (GFM); hiển thị đúng trên GitHub, VS Code và các trình xem Markdown thông dụng.
- Sinh từ **một template cố định** (Jinja2), nên mọi report có cùng cấu trúc và thứ tự mục.
- **Câu trả lời đứng đầu:** mục "Answer" ở đầu file trả lời câu hỏi chính trong tối đa 3 câu, sinh tự động theo quy tắc kết luận.
- Đọc được độc lập, không cần mở file khác; hình được nhúng bằng đường dẫn tương đối.
- Quy ước số: accuracy 1 chữ số thập phân; Δ có dấu (`+0.4`, `−3.2`); p 2 chữ số có nghĩa, dưới 0.001 ghi `<0.001`; số lớn có dấu phẩy ngăn cách hàng nghìn; cột số căn phải.
- Accuracy cao nhất của mỗi backbone in **đậm**; hàng baseline và hàng upper bound được ghi rõ.
- Nhãn kết luận dùng ký hiệu cố định `▲` `▼` `●` kèm chữ, để đọc được cả khi in trắng đen.
- Cuối report có mục "How to read this report" giải thích mọi thuật ngữ, để người mới đọc hiểu mà không cần tài liệu khác.

### 2.3. Cấu trúc `report.md` (mẫu đầy đủ, số liệu minh họa)

Dưới đây là đúng nội dung một report ở chế độ `synthetic`. Ở chế độ `native-lr`, mục 6 được thay bằng một dòng `n/a (no HR reference in native-lr mode)`, và hàng `HR (upper bound)` không xuất hiện.

````markdown
# SR4Rec Report: `ear_demo`

> **Question.** Does placing a super-resolution (SR) model in front of the recognizer
> improve accuracy on this dataset, compared with plain bicubic upscaling?
>
> **Answer.** No SR model improved accuracy significantly on any backbone.
> Real-ESRGAN reduced accuracy significantly on 3 of 3 backbones.

| Run | SR4Rec | Finished | Total time |
|---|---|---|---|
| `ear_demo_2026-10-15_1432` | 0.1.0 | 2026-10-15 15:10 (UTC+07:00) | 38 min |

## 1. Summary

| Backbone | Best SR | Δ vs bicubic (pp) | Verdict |
|---|---|---:|---|
| ResNet-18 | SwinIR | +0.6 | ● no difference |
| MobileNetV3-Small | SPAN | +0.3 | ● no difference |
| ConvNeXt-Tiny | SwinIR | +0.2 | ● no difference |

## 2. Setup

| Item | Value |
|---|---|
| Dataset | `data/ear_demo` (1,000 images, 100 classes) |
| Mode | `synthetic`: HR images downsampled ×4 (MATLAB-style bicubic) |
| Protocol | `matched`: train, val and test images all pass through the same SR model; one recognizer per SR model, backbone and seed |
| Split | created by SR4Rec from ratios 0.70 / 0.10 / 0.20 (split seed 0): train 700 / val 100 / test 200 images |
| Recognizer input | 224 × 224, letterbox |
| Seeds | 0, 1, 2 |

**SR models**

| Name | Scale | Trained for | Weights file | SHA-256 |
|---|---:|---|---|---|
| bicubic (baseline) | ×4 | n/a | n/a | n/a |
| Real-ESRGAN | ×4 | real-world degradation | `RealESRGAN_x4plus.pth` | `4fa0d38…` |
| SwinIR (classical) | ×4 | bicubic degradation | `001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth` | `9a3c1f2…` |
| SwinIR (real-world) | ×4 | real-world degradation | `003_realSR_BSRGAN_DFO_s64w8_SwinIR-M_x4_GAN.pth` | `51e0c6a…` |
| SPAN | ×4 | bicubic degradation | `spanx4_ch48.pth` | `b27e05d…` |

## 3. Main results

Rank-1 accuracy (the primary metric) is the mean ± standard deviation over 3 seeds.
Δ, 95% CI and p compare each SR model with bicubic on the same 200 test images.
"Same sign" counts the seeds whose Δ has the same sign as the mean Δ.

| Backbone | SR | Rank-1 (%) | Δ vs bicubic (pp) | 95% CI (pp) | p (Holm) | Same sign | Verdict |
|---|---|---:|---:|---|---:|---:|---|
| ResNet-18 | bicubic (baseline) | 78.3 ± 0.6 | | | | | |
| ResNet-18 | Real-ESRGAN | 75.1 ± 0.9 | −3.2 | [−4.6, −1.8] | <0.001 | 3/3 | ▼ significant harm |
| ResNet-18 | SwinIR (classical) | **78.9 ± 0.4** | +0.6 | [−0.5, +1.7] | 0.62 | 2/3 | ● no difference |
| ResNet-18 | SwinIR (real-world) | 76.0 ± 0.7 | −2.3 | [−3.6, −1.0] | 0.002 | 3/3 | ▼ significant harm |
| ResNet-18 | SPAN | 78.7 ± 0.5 | +0.4 | [−0.7, +1.5] | 0.62 | 2/3 | ● no difference |
| ResNet-18 | HR (upper bound) | 86.0 ± 0.3 | | | | | |

*(one block per backbone)*

## 4. Rank-5, CMC, precision, recall and F1

![CMC curves](plots/cmc.png)

Precision, recall and F1 are macro-averaged over classes; mean ± standard deviation over 3 seeds. These metrics are
descriptive: the statistical test and the verdict use accuracy, the primary metric.

| Backbone | SR | Rank-1 (%) | Rank-5 (%) | Precision (%) | Recall (%) | F1 (%) |
|---|---|---:|---:|---:|---:|---:|
| ResNet-18 | bicubic (baseline) | 78.3 ± 0.6 | 92.1 ± 0.4 | 79.0 ± 0.7 | 78.3 ± 0.6 | 77.9 ± 0.6 |
| ResNet-18 | Real-ESRGAN | 75.1 ± 0.9 | 90.3 ± 0.6 | 76.2 ± 1.0 | 75.1 ± 0.9 | 74.6 ± 0.9 |
| ResNet-18 | SwinIR (classical) | **78.9 ± 0.4** | **92.6 ± 0.3** | **79.6 ± 0.5** | **78.9 ± 0.4** | **78.5 ± 0.4** |
| ResNet-18 | SPAN | 78.7 ± 0.5 | 92.4 ± 0.4 | 79.3 ± 0.6 | 78.7 ± 0.5 | 78.2 ± 0.5 |
| ResNet-18 | HR (upper bound) | 86.0 ± 0.3 | 96.0 ± 0.2 | 86.4 ± 0.3 | 86.0 ± 0.3 | 85.8 ± 0.3 |

*(one block per backbone)*

## 5. Results by image size

Size bins use the short side of the LR image given to the SR model.

![Accuracy by LR image size](plots/accuracy_by_size.png)

| Backbone | SR | <32 px | 32–63 px | 64–127 px | ≥128 px |
|---|---|---|---|---|---|
| ResNet-18 | Real-ESRGAN | insufficient data (41) | ▼ −4.1 | ▼ −2.9 | ● −0.4 |
| ResNet-18 | SwinIR | insufficient data (41) | ● +1.2 | ● +0.3 | ● +0.1 |

Cells show Δ vs bicubic in pp and the verdict. The number in brackets is the count of test
images in a bin with fewer than 50 images.

## 6. Image quality vs recognition

![PSNR and SSIM vs accuracy](plots/quality_vs_accuracy.png)

| SR | PSNR (dB) | SSIM | Accuracy, ResNet-18 (%) | F1, ResNet-18 (%) |
|---|---:|---:|---:|---:|
| bicubic | 26.10 | 0.781 | 78.3 | 77.9 |
| Real-ESRGAN | 24.85 | 0.742 | 75.1 | 74.6 |
| SwinIR (classical) | **27.92** | **0.832** | **78.9** | **78.5** |
| SwinIR (real-world) | 25.40 | 0.760 | 76.0 | 75.5 |
| SPAN | 27.60 | 0.825 | 78.7 | 78.2 |

Highest PSNR: SwinIR. Highest SSIM: SwinIR. Highest accuracy: SwinIR (ResNet-18), SPAN (MobileNetV3-Small),
SwinIR (ConvNeXt-Tiny).

## 7. CPU latency

Batch 1, LR input 64 × 64, 4 threads, Intel Core i7-12700 (median / p95, ms).

| SR | SR | ResNet-18 | Pipeline |
|---|---:|---:|---:|
| bicubic | 0.3 / 0.4 | 11.8 / 12.6 | 12.1 / 13.0 |
| SPAN | 21.4 / 23.0 | 11.8 / 12.6 | 33.2 / 35.5 |

## 8. Visual comparisons

Before-SR and after-SR panels for 24 test images (8 corrected by at least one SR model,
8 degraded by at least one SR model, 8 random; selection seed 0). All panels:
`comparisons/`. Two examples:

![Comparison 01](comparisons/01_Abyssinian_Abyssinian_10.png)
![Comparison 02](comparisons/02_beagle_beagle_122.png)

## 9. Warnings and notes

- SR weights were trained on natural images (DIV2K and similar) and may not match this dataset.
- Real-ESRGAN and SwinIR (real-world) were trained for real-world degradation, but the LR images
  of this run were made by clean bicubic downsampling (synthetic mode). Their results here reflect
  that mismatch; see a native-lr run for real low-resolution images.
- 41 test images fall in the <32 px bin; no test is reported for that bin.

## 10. How to read this report

- **Δ vs bicubic (pp):** accuracy of the SR model minus accuracy of bicubic, in percentage points.
- **95% CI:** range that contains the true Δ with 95% confidence (bootstrap over test images).
- **p (Holm):** probability of a Δ this large if the SR model and bicubic were equivalent,
  corrected for comparing several SR models.
- **Verdict:** ▲ significant gain, ▼ significant harm, ● no difference
  (rules: docs/report_guide.md).
- **Rank-1 / Rank-5:** the true identity is the top prediction / among the top 5 predictions.
  CMC shows Rank-k for k = 1 to 10.
- **Same sign:** in how many seeds the difference with bicubic points the same way.
- **Precision, recall, F1:** macro averages over classes (every class counts equally).
  Recall equals accuracy computed per class and then averaged.
- **PSNR / SSIM:** image similarity between the SR output and the HR image
  (Y channel, border of `scale` pixels removed); synthetic mode only.
- **HR (upper bound):** accuracy on the original high-resolution test images.

## 11. Reproducibility

Configuration: `sr4rec.yaml`. Environment, data hash and weight hashes: `fingerprint.yaml`.
Re-run: `sr4rec run runs/ear_demo_2026-10-15_1432/sr4rec.yaml`
Re-grade without training (published demos only): `sr4rec reproduce <demo> --eval-only`
````

Các câu trong mục "Answer", "Summary" và dòng tổng kết ở mục 6 được sinh theo quy tắc cố định từ bảng số liệu, không có diễn giải thêm.

### 2.4. Đặc tả file cấu hình `sr4rec.yaml`

**Quy định bắt buộc:**
- Mọi khóa trong file do `init` sinh ra đều có comment tiếng Anh ghi đủ 4 thông tin: `type`, `required`, `default`, `allowed`.
- Khóa nhận giá trị enum phải liệt kê **đầy đủ mọi giá trị hợp lệ** và ý nghĩa của từng giá trị.
- Khóa số phải ghi rõ khoảng giá trị hợp lệ.
- Khóa không có trong đặc tả bị **từ chối** (báo lỗi), để lỗi gõ sai không bị bỏ qua âm thầm.
- Giá trị không hợp lệ bị từ chối với thông báo nêu tên khóa, giá trị sai và danh sách giá trị hợp lệ. Ví dụ: `mode: "native_lr" is not allowed. Allowed values: synthetic, native-lr.`
- Đặc tả có **một nguồn duy nhất** trong code (schema pydantic). Comment trong file do `init` sinh ra và `docs/config_reference.md` đều được sinh từ schema này, nên không bao giờ lệch nhau (kiểm tra ở B5.6).

**File `sr4rec.yaml` đầy đủ do `init` sinh ra:**

```yaml
# =============================================================================
# SR4Rec configuration file (SR4Rec v0.1.0)
#
# Generated by `sr4rec init`. Lines marked [CHECK] were inferred by SR4Rec:
# confirm or edit the value, then delete the "[CHECK]" marker.
# `sr4rec run` refuses to start while any [CHECK] marker remains.
#
# Each key is documented with:
#   type     : value type
#   required : yes | no | conditional
#   default  : value used when the key is omitted
#   allowed  : the complete list of accepted values, or the valid range
#
# Unknown keys are rejected, so typos never pass silently.
# Full reference: docs/config_reference.md
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Dataset
# -----------------------------------------------------------------------------

# Dataset folder. It must contain `images/` and `labels.csv`
# (see docs/preparing_dataset.md). A relative path is resolved from the folder
# that contains this file. Recommended location: data/<dataset_name>.
#   type: path | required: yes
dataset: data/ear_demo

# Resolution of the images in `images/`.
#   type: enum | required: yes
#   allowed:
#     synthetic : images are high resolution (HR). SR4Rec downsamples the test
#                 images by `scale`; PSNR/SSIM and an HR upper bound are reported.
#     native-lr : images are already low resolution. No downsampling; PSNR/SSIM
#                 are not available (there is no HR reference).
mode: synthetic  # [CHECK] suggested: median short side 240 px >= 112 px

# Upscaling factor. In `synthetic` mode it is also the downsampling factor.
# Every SR model below must have exactly this scale, otherwise the run stops.
#   type: integer (enum) | required: no | default: 4
#   allowed: 2 | 3 | 4
scale: 4

# How the recognizer is trained with respect to SR.
#   type: enum | required: no | default: matched
#   allowed:
#     matched          : for every SR model (and bicubic), the train, val and test
#                        images all pass through that SR model; one recognizer is
#                        trained per SR model, backbone and seed. Answers: "does a
#                        system built with this SR model recognize better?"
#     fixed_recognizer : one recognizer per backbone and seed, trained on HR images
#                        (synthetic) or bicubic-upscaled images (native-lr); only the
#                        test images pass through SR. Answers: "does adding SR in
#                        front of an existing recognizer help?" Much cheaper.
protocol: matched


# -----------------------------------------------------------------------------
# 2. Train / val / test split
# -----------------------------------------------------------------------------
split:
  # Where the train/val/test assignment comes from.
  #   type: enum | required: no | default: auto
  #   allowed:
  #     auto   : use the `split` column of labels.csv if it exists,
  #              otherwise split by `ratios`
  #     column : use the `split` column; stop with an error if it is missing
  #     ratios : ignore any `split` column and split by `ratios`
  source: auto

  # Fractions of images for each split, used when SR4Rec creates the split.
  # Applied inside every class (each class keeps at least one image in train,
  # val and test). The report prints the actual counts.
  #   type: mapping with keys train, val, test | required: no
  #   default: {train: 0.7, val: 0.1, test: 0.2}
  #   allowed: each value greater than 0 and less than 1; the three values
  #            must sum to 1.0
  ratios:
    train: 0.7
    val: 0.1
    test: 0.2

  # Fraction of the train images moved to val when the `split` column has
  # train and test rows but no val rows.
  #   type: float | required: no | default: 0.1
  #   allowed: greater than 0, at most 0.5
  val_from_train: 0.1

  # Seed used to create the split. It is independent of the recognizer seeds,
  # so all recognizer seeds share the same split.
  #   type: integer | required: no | default: 0 | allowed: 0 to 2147483647
  seed: 0


# -----------------------------------------------------------------------------
# 3. SR models
#
# The bicubic baseline is always added automatically; do not list it.
# Each entry needs `name` and ONE source (step-by-step guide:
# docs/adding_sr_models.md; runnable examples: examples/configs/02, 06, 07):
#   method 1 (weights) : `weights` only           -> loaded with spandrel
#   method 2 (module)  : `module` (+ `weights`)   -> your own PyTorch class
#   method 3 (images)  : `images` only            -> pre-computed SR images
# Check every entry with `sr4rec run <config> --dry-run` before a real run.
#
#   name    : type: string | required: yes
#             allowed: letters, digits, "_" and "-"; must be unique;
#             "bicubic" and "hr" are reserved.
#   weights : type: path | required: conditional (method 1; optional in method 2)
#             allowed: method 1: a .pth or .safetensors file whose architecture
#             spandrel can detect; its scale is read from the file and must
#             equal `scale`. Method 2: any file; it is passed to the class as
#             __init__(weights=<path>). Recommended location: weights/.
#   module  : type: string "<file.py>:<ClassName>" | required: conditional (method 2)
#             allowed: a Python file and a torch.nn.Module class with an integer
#             attribute `scale` equal to `scale` and forward(x) mapping
#             (N, 3, H, W) in [0, 1] to (N, 3, H*scale, W*scale).
#             Recommended location: sr_models/.
#   images  : type: path | required: conditional (method 3; no other source key)
#             allowed: a folder of PNG images with the same relative paths as the
#             dataset images: train, val and test images for protocol `matched`,
#             test images only for `fixed_recognizer`. Build them from
#             runs/<run_name>/lr/ (synthetic) or from `images/` (native-lr).
#             Recommended location: sr_images/<name>/.
#             CPU latency is not measured for this source.
#   tile    : type: integer or null | required: no | default: null
#             allowed: null (process the whole image) | 64 to 1024 (LR tile size
#             in pixels; tiles overlap by 16 px). Use it only if the GPU runs
#             out of memory. Valid for methods 1 and 2 only.
# -----------------------------------------------------------------------------
sr:
  - name: realesrgan
    weights: weights/RealESRGAN_x4plus.pth
  - name: swinir_classical
    weights: weights/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth
  - name: swinir_real
    weights: weights/003_realSR_BSRGAN_DFO_s64w8_SwinIR-M_x4_GAN.pth
  - name: span
    weights: weights/spanx4_ch48.pth
  # - name: my_sr                                   # method 2
  #   module: sr_models/tiny_espcn.py:TinyESPCN
  #   weights: weights/tiny_espcn_x4.pth
  # - name: my_method                               # method 3
  #   images: sr_images/my_method/


# -----------------------------------------------------------------------------
# 4. Recognizer
# -----------------------------------------------------------------------------
recognizer:
  # Recognition backbones (timm model names, ImageNet-pretrained, fine-tuned).
  #   type: list of strings | required: no
  #   default: [resnet18, mobilenetv3_small_100, convnext_tiny]
  #   allowed: validated by SR4Rec: resnet18 | mobilenetv3_small_100 | convnext_tiny
  #            any other timm model name runs with an "experimental" warning
  backbones: [resnet18, mobilenetv3_small_100, convnext_tiny]

  # Side length of the square recognizer input (letterbox, aspect ratio kept).
  #   type: integer | required: no | default: 224
  #   allowed: 64 to 512, multiple of 32
  input_size: 224

  # Random seeds. One recognizer is trained per backbone and seed.
  #   type: list of integers | required: no | default: [0, 1, 2]
  #   allowed: 1 to 10 distinct integers from 0 to 2147483647
  #            (3 or more recommended)
  seeds: [0, 1, 2]


# -----------------------------------------------------------------------------
# 5. Training (recognizer only; SR models are never trained)
# -----------------------------------------------------------------------------
training:
  # Number of training epochs. The checkpoint with the best val accuracy is kept.
  #   type: integer | required: no | default: 30 | allowed: 1 to 500
  epochs: 30

  # Mini-batch size.
  #   type: integer | required: no | default: 64 | allowed: 1 to 1024
  batch_size: 64

  # AdamW learning rate (cosine schedule, 1 warm-up epoch).
  #   type: float | required: no | default: 3.0e-4 | allowed: greater than 0, at most 1.0
  learning_rate: 3.0e-4

  # AdamW weight decay.
  #   type: float | required: no | default: 0.05 | allowed: 0.0 to 1.0
  weight_decay: 0.05

  # Random horizontal flip during training. Off by default because flipping can
  # remove identity cues (e.g. left vs right ear).
  #   type: boolean | required: no | default: false | allowed: true | false
  horizontal_flip: false

  # Data-loading worker processes.
  #   type: integer | required: no | default: 4 | allowed: 0 to 64
  num_workers: 4


# -----------------------------------------------------------------------------
# 6. CPU latency benchmark
# -----------------------------------------------------------------------------
latency:
  # Measure CPU latency of each SR model, each backbone and the full pipeline.
  #   type: boolean | required: no | default: true | allowed: true | false
  enabled: true

  # Side length of the square LR input used for timing.
  #   type: integer | required: no | default: 64 | allowed: 16 to 512
  lr_size: 64

  # Number of CPU threads used for timing.
  #   type: integer | required: no | default: 4 | allowed: 1 to 64
  threads: 4


# -----------------------------------------------------------------------------
# 7. Visual comparisons (before SR / after SR)
# -----------------------------------------------------------------------------
comparisons:
  # Export one PNG per selected test image that combines the LR input, bicubic,
  # every SR model and (synthetic mode) the HR image, each with an English caption:
  # method name, predicted label with correct/wrong mark, and PSNR/SSIM
  # (synthetic mode only).
  #   type: boolean | required: no | default: true | allowed: true | false
  enabled: true

  # Number of test images to export.
  #   type: integer | required: no | default: 24 | allowed: 1 to 1000
  count: 24

  # How the test images are chosen.
  #   type: enum | required: no | default: mixed
  #   allowed:
  #     mixed  : one third corrected by at least one SR model (bicubic wrong, SR right),
  #              one third degraded by at least one SR model (bicubic right, SR wrong),
  #              one third random; fixed selection seed 0
  #     random : uniformly at random from the test set; fixed selection seed 0
  #     all    : every test image (ignores `count`; can produce many files)
  selection: mixed

  # Backbone and seed whose predictions are written in the captions.
  #   type: string or null | required: no | default: null
  #   allowed: null (first backbone in `recognizer.backbones`, first seed) |
  #            any name listed in `recognizer.backbones`
  backbone: null


# -----------------------------------------------------------------------------
# 8. Runtime
# -----------------------------------------------------------------------------
runtime:
  # Device for SR inference and recognizer training.
  #   type: enum | required: no | default: auto
  #   allowed:
  #     auto : use a CUDA GPU if one is available, otherwise the CPU
  #     cuda : require a CUDA GPU; stop with an error if none is found
  #     cpu  : always use the CPU (slow; intended for small datasets and tests)
  device: auto

  # Parent folder for all runs.
  #   type: path | required: no | default: runs
  output_dir: runs

  # Folder for cached SR outputs and trained recognizer checkpoints, shared by
  # all runs so that repeated runs are fast. Deleting it is always safe.
  #   type: path or null | required: no | default: null
  #   allowed: null (use <output_dir>/.cache) | any folder path
  cache_dir: null

  # Name of this run's folder inside `output_dir`.
  #   type: string or null | required: no | default: null
  #   allowed: null (automatic: <dataset>_<YYYY-MM-DD>_<HHMM>) |
  #            letters, digits, "_" and "-"
  run_name: null
```

**Các giá trị cố định, không đưa vào config** (theo quy tắc phương pháp 1.3, để mọi report so sánh được với nhau): nhóm kích thước ảnh; số lần lặp bootstrap và hoán vị (10.000); ngưỡng ý nghĩa 0.05; ngưỡng 50 ảnh cho `insufficient data`; kernel hạ mẫu bicubic kiểu MATLAB; số lần đo latency. Các giá trị này được in trong mục Setup của report và mô tả trong `docs/methods.md`.

### 2.5. Đặc tả ảnh so sánh trước/sau SR (`comparisons/`)

- **Một file PNG cho mỗi ảnh test được chọn**, tên file `<NN>_<path>.png` (dấu `/` trong `path` đổi thành `_`). `comparisons/index.csv` ghi `path`, nhãn đúng, lý do được chọn (`corrected`, `degraded`, `random`) và tên file.
- **Bố cục một hàng**, các ô cùng kích thước hiển thị (ảnh nhỏ được phóng to bằng nearest-neighbour chỉ để hiển thị, để không che mất chi tiết thật):
  `LR input` → `Bicubic` → mỗi mô hình SR theo thứ tự trong config → `HR (reference)` (chỉ ở `synthetic`).
- **Chú thích bằng tiếng Anh** (bắt buộc, mục 1.4):
  - Tiêu đề: `path`, nhãn đúng, backbone và seed dùng để dự đoán, protocol. Ví dụ: `Abyssinian/Abyssinian_10.jpg | true: Abyssinian | ResNet-18, seed 0 | protocol: matched`.
  - Dưới mỗi ô: tên phương pháp; `pred: <label>` kèm dấu đúng (✓, viền xanh) hoặc sai (✗, viền cam); ở `synthetic` thêm `PSNR 27.9 dB | SSIM 0.832`. Ô `LR input` ghi kích thước thật, ví dụ `LR input (32 × 29 px)`.
- Màu viền phân biệt được khi in trắng đen (viền đúng là nét liền, viền sai là nét đứt).
- Font DejaVu Sans đi kèm matplotlib, để ảnh giống nhau trên mọi hệ điều hành.
- `report.md` nhúng 2 ảnh đầu tiên và dẫn tới thư mục `comparisons/`.
- Cùng một hàm vẽ được dùng cho Hình 4 (ví dụ định tính) của bài báo, nên hình trong bài và ảnh người dùng nhận được có cùng quy ước.

Ví dụ một ảnh gộp (mô tả bố cục):
```
+-----------------------------------------------------------------------------------+
| Abyssinian/Abyssinian_10.jpg | true: Abyssinian | ResNet-18, seed 0 | protocol: matched |
+-------------+-------------+-------------+-------------+-------------+-------------+
|  LR input   |   Bicubic   | Real-ESRGAN |   SwinIR    |    SPAN     |     HR      |
| (64 x 58 px)|             |             |             |             | (reference) |
+-------------+-------------+-------------+-------------+-------------+-------------+
|             | pred: Bengal| pred: Bengal| pred: Abyss.| pred: Abyss.| pred: Abyss.|
|             |   wrong     |   wrong     |   correct   |   correct   |   correct   |
|             | PSNR 26.1   | PSNR 24.9   | PSNR 27.9   | PSNR 27.6   |             |
|             | SSIM 0.781  | SSIM 0.742  | SSIM 0.832  | SSIM 0.825  |             |
+-------------+-------------+-------------+-------------+-------------+-------------+
```

---

## Phần A. Xây dựng tool

Mỗi đầu việc có: **ID · việc cần làm · đầu ra · tiêu chí hoàn thành**.

### A0. Chuẩn bị (tuần 1)

| ID | Việc | Đầu ra | Hoàn thành khi |
|---|---|---|---|
| A0.1 | Tra trùng lặp: Scopus (`SRCTITLE("SoftwareX") AND TITLE-ABS-KEY("super-resolution" AND ("recognition" OR "classification"))`), GitHub, PyPI, arXiv | Bảng công cụ liên quan và điểm khác biệt | Có kết luận đi tiếp, được thầy đồng ý |
| A0.2 | Kiểm tra tên `sr4rec` trên PyPI, GitHub, Google Scholar | Tên chính thức | Tên chưa bị dùng |
| A0.3 | Gặp thầy chốt các quyết định ở mục 7 | Biên bản ngắn | Có quyết định bằng văn bản |
| A0.4 | Kiểm tra: spandrel nạp được đúng 4 file trọng số chính thức (Real-ESRGAN x4plus, SwinIR-M x4 classical, SwinIR-M x4 real-world GAN, SPAN x4); giấy phép mã nguồn và trọng số của 4 SR, spandrel, timm | Bảng kiểm tra + bảng giấy phép | Nạp được cả 3 file; chọn được giấy phép cho SR4Rec (dự kiến MIT) |
| A0.5 | Chốt dataset demo và dataset mẫu; đọc và lưu nguyên văn điều khoản sử dụng của Oxford-IIIT Pet và EarVN1.0; xin văn bản cho phép của tác giả EarVN1.0 để đóng gói `earvn_mini` | Danh sách dataset + bản lưu điều khoản + văn bản cho phép (hoặc quyết định dùng phương án dự phòng 1.6.1) | Đã có dữ liệu trên máy và biết chắc được đóng gói hay không |

### A1. Khung dự án (tuần 1)

| ID | Việc | Đầu ra | Hoàn thành khi |
|---|---|---|---|
| A1.1 | Repo GitHub, `src/sr4rec/`, `pyproject.toml`, `LICENSE`, `.gitignore` | Repo cài được | `pip install -e .` chạy trên Linux và Windows |
| A1.2 | `ruff`, `pre-commit`, `pytest` | Cấu hình | `pre-commit run --all-files` sạch |
| A1.3 | CI GitHub Actions: lint + test trên Ubuntu, Windows, macOS; Python 3.10–3.12; bước quét tiếng Việt (B5.3) | `.github/workflows/ci.yml` | Pipeline xanh |
| A1.4 | Schema config bằng pydantic, là nguồn duy nhất của đặc tả mục 2.4 (kiểu, mặc định, enum, khoảng giá trị, mô tả); từ chối khóa lạ; lỗi nêu tên khóa, giá trị sai và danh sách giá trị hợp lệ | `config.py` | Config sai bị từ chối với thông báo rõ ràng (B1.10) |
| A1.5 | Class `Run` duy nhất; CLI chỉ gọi `Run` | `run.py`, `cli.py` | CLI và API Python cho cùng kết quả (test) |
| A1.6 | Fingerprint: config đã hợp nhất, seed, phiên bản Python/PyTorch/CUDA/driver, commit, GPU/CPU, SHA-256 của `labels.csv`, của `split.csv` và của mọi file trọng số | `fingerprint.yaml` | Tạo tự động ở mọi lần chạy |
| A1.7 | Sinh tự động từ schema: file `sr4rec.yaml` có comment đầy đủ (dùng cho `init`) và `docs/config_reference.md` | `config_docs.py` | Đầu ra khớp mẫu mục 2.4; B5.6 đạt |

### A2. Module `data` (tuần 2)

| ID | Việc | Đầu ra | Hoàn thành khi |
|---|---|---|---|
| A2.1 | Đọc `images/` + `labels.csv` theo đúng quy định 1.2 | `data/dataset.py` | Đọc đúng dataset mẫu |
| A2.2 | Kiểm tra format: thiếu cột, `path` trùng hoặc không tồn tại, ảnh không đọc được, định dạng không hỗ trợ, lớp không đủ ảnh để chia theo `split.ratios`, lớp không có ảnh ở một trong ba tập khi dùng cột `split`, ảnh trùng nội dung (SHA-256) giữa các tập, giá trị `split` không hợp lệ | Báo lỗi theo số dòng | Bắt đủ mọi lỗi trên dataset lỗi cố ý |
| A2.3 | Chia dữ liệu theo khối `split` của config và quy định 1.2: ba giá trị `source`, tỉ lệ do người dùng nhập, `val_from_train`, `seed`; ghi tỉ lệ khai báo và số ảnh thực tế | `split.csv` | Test B1.1–B1.4 và B1.11 đạt |
| A2.4 | Khóa phép chia: lưu `split.csv` kèm SHA-256 của `labels.csv` và của khối `split`; dữ liệu hoặc khai báo thay đổi thì tạo phép chia mới và cảnh báo | Cơ chế khóa | Chạy lại với cùng khai báo không tạo phép chia mới |
| A2.5 | Thống kê kích thước và gán nhóm kích thước (4 nhóm cố định) | Hàm dùng chung | Khớp tính tay |

### A3. Hạ mẫu và chuẩn hóa kích thước (tuần 3)

| ID | Việc | Đầu ra | Hoàn thành khi |
|---|---|---|---|
| A3.1 | Bicubic kiểu MATLAB (có antialias), cài theo BasicSR, ghi nguồn đúng giấy phép | `lr/resize.py` | B2.3 đạt |
| A3.2 | Chế độ `synthetic`: mod-crop ảnh HR của cả ba tập theo `scale`, hạ mẫu, lưu vào `lr/train/`, `lr/val/`, `lr/test/` | Hàm `make_lr` | Kích thước đúng; tên file giữ nguyên `path` |
| A3.3 | Letterbox về kích thước đầu vào bộ nhận dạng | `lr/letterbox.py` | Test kích thước biên đạt (B1.5) |

### A4. Module `sr` (tuần 3–4)

| ID | Việc | Đầu ra | Hoàn thành khi |
|---|---|---|---|
| A4.1 | Giao diện chung: tensor LR RGB float [0,1] NCHW vào, tensor SR ra; có thuộc tính `scale`; xử lý yêu cầu kích thước đầu vào (đệm reflect tới bội số cần thiết, cắt lại đầu ra; yêu cầu lấy từ spandrel hoặc thuộc tính tùy chọn `size_multiple` của class) (mục 1.8, điểm 2) | Base class | Mọi nguồn SR tuân theo; ảnh 13×17 px chạy được với SwinIR |
| A4.2 | Bicubic baseline: phóng to ×`scale` bằng cùng hàm resize của A3.1 | Wrapper | Khớp A3.1 |
| A4.3 | Nguồn `.pth`: nạp qua spandrel, đọc kiến trúc và hệ số từ file, tính SHA-256; hệ số khác `scale` thì dừng; spandrel không nhận được kiến trúc thì báo lỗi và hướng dẫn dùng nguồn thư mục ảnh | `sr/pth_source.py` | Nạp đúng 3 file kiểm chứng; B2.1 đạt |
| A4.4 | Nguồn thư mục ảnh: ghép theo `path`; báo file thiếu, file thừa, kích thước sai (khác `scale` × kích thước LR) | `sr/folder_source.py` | Test B1.6 đạt |
| A4.5 | Suy luận theo ô (tile) có chồng lấn khi ảnh quá lớn cho GPU | Tùy chọn `tile` | Tile và không tile khớp trong dung sai |
| A4.6 | Cache ảnh SR theo mã băm (SHA-256 trọng số + ảnh LR + tham số), cho cả ba tập; với `matched`, SR chạy trên train, val và test; với `fixed_recognizer`, chỉ trên test | Cache | Chạy lại không tính lại SR |
| A4.7 | Nguồn `module` (cách 2): nạp file `.py` bằng importlib, khởi tạo class với `weights`, kiểm tra giao diện (là `nn.Module`, có `scale` nguyên bằng config, đầu ra đúng kích thước, float, không NaN trên tensor thử); SHA-256 của file `.py` và trọng số vào fingerprint | `sr/module_source.py` | B1.13 đạt |

### A5. Module `rec` (tuần 5)

| ID | Việc | Đầu ra | Hoàn thành khi |
|---|---|---|---|
| A5.1 | Tạo backbone từ timm, pretrained ImageNet, thay lớp phân loại | Factory | 3 backbone kiểm chứng tạo được; tên khác có cảnh báo `experimental` |
| A5.2 | Công thức train cố định: AdamW (lr 3e-4, weight decay 0.05), cosine, 1 epoch warmup, 30 epoch, batch 64, AMP; augmentation nhẹ (RandomResizedCrop scale 0.8–1.0, ColorJitter nhỏ; mặc định không lật ngang vì có thể làm mất đặc trưng nhận dạng, ví dụ tai trái và tai phải); chọn checkpoint theo accuracy trên `val` | `rec/engine.py` | Chạy được trên dataset mẫu |
| A5.3 | Nguồn ảnh train và val theo `protocol` (quy tắc 1.3.8): `matched` dùng ảnh train/val đã qua đúng mô hình SR của bộ nhận dạng đó (cộng một bộ nhận dạng HR upper bound ở `synthetic`); `fixed_recognizer` dùng HR (`synthetic`) hoặc LR phóng to bicubic (`native-lr`) | Theo protocol | Report ghi rõ protocol; test B1.15 đạt |
| A5.4 | Chế độ tất định: `torch.use_deterministic_algorithms`, seed cho mọi worker của dataloader | Cấu hình | B4.1 đạt |
| A5.5 | Cache checkpoint theo mã băm (config train + backbone + seed + `split.csv` + nguồn ảnh train: SHA-256 của mô hình SR với `matched`) | Cache | Với `matched`, thêm SR mới chỉ train bộ nhận dạng cho SR đó; với `fixed_recognizer`, thêm SR mới không train lại |

### A6. Module `eval` và `stats` (tuần 6)

| ID | Việc | Đầu ra | Hoàn thành khi |
|---|---|---|---|
| A6.1 | Dự đoán cho mọi (backbone × SR × seed), cộng hàng HR upper bound ở `synthetic` | `predictions.csv` | Đủ mọi tổ hợp |
| A6.2 | Rank-1 accuracy, Rank-5 accuracy, CMC (Rank-1 đến Rank-10), macro precision, macro recall, macro F1 (`zero_division=0`), theo toàn bộ và theo nhóm kích thước | `metrics.csv`, `cmc.csv` | Khớp scikit-learn (B2.5) và tính tay (B1.17) |
| A6.3 | PSNR/SSIM kênh Y, cắt viền `scale` px (chỉ `synthetic`) | Cột trong `metrics.csv` | B2.2 đạt |
| A6.4 | Thống kê theo 1.3: bootstrap CI, kiểm định hoán vị cặp, Holm; nhãn kết luận; cột "same sign" (số seed có Δ cùng dấu với Δ trung bình) | `stats.csv` | B2.4, B1.17 đạt |

### A7. Report, latency và CLI (tuần 7)

| ID | Việc | Đầu ra | Hoàn thành khi |
|---|---|---|---|
| A7.1 | Template Jinja2 cho `report.md` đúng đặc tả mục 2.2–2.3 | `report/template.md.j2` | Snapshot test và markdownlint đạt (B5.4) |
| A7.2 | Ba biểu đồ (matplotlib): Rank-1 theo nhóm kích thước; đường CMC; PSNR và SSIM so với Rank-1 (hai panel); chữ tiếng Anh, bảng màu phân biệt được khi in trắng đen | `plots/*.png` | Kiểm tra bằng mắt + test sinh file |
| A7.3 | `table.tex` (booktabs) cho bảng kết quả chính | `table.tex` | Biên dịch không lỗi |
| A7.4 | Đo latency CPU theo quy định 1.1 | `latency.csv` | Tái lập được trên cùng máy (lệch dưới 10%) |
| A7.5 | `init`: ghi `sr4rec.yaml` vào thư mục hiện tại (không ghi đè nếu không có `--force`), kiểm tra dataset (A2.2), thống kê kích thước, sinh `sr4rec.yaml` đầy đủ comment theo mục 2.4 (dùng A1.7), có `mode` kèm `[CHECK]`. Quy tắc gợi ý `mode`: cạnh ngắn trung vị ≥ 112 px (một nửa đầu vào 224) → `synthetic`, ngược lại → `native-lr` | Lệnh | Gợi ý đúng trên 2 dataset mẫu |
| A7.6 | `run`: toàn bộ quy trình, bỏ qua bước đã cache, từ chối config còn `[CHECK]`, in tóm tắt 4–5 dòng. Cờ `--dry-run`: kiểm tra config và dataset, nạp mọi SR, chạy mỗi SR trên 2 ảnh test, in bảng kiểm tra (mục 1.6.3), in **số lần train dự kiến và ước tính thời gian** (đo từ một mini-epoch chạy thử cho mỗi backbone) và số ảnh SR cần tính, không train | Lệnh | Chạy lại lần hai chỉ vài giây; `--dry-run` xong dưới 1 phút trên dataset mẫu |
| A7.7 | `reproduce <demo>`: chạy config demo có sẵn và so với `expected_results/<demo>.yaml`; mã thoát 0 = đạt, 2 = lệch số liệu, 3 = thiếu dữ liệu hoặc trọng số; mặc định tìm dữ liệu trong `data/` và trọng số trong `weights/` (mục 1.5), đổi bằng `--data-root`, `--weights-root`; demo `quickstart` dùng `pets_mini` và SR `tiny_espcn` (config `01_quickstart.yaml`), chạy trên CPU | Lệnh | B4.3, B4.4 đạt |
| A7.8 | Tài nguyên mẫu mục 1.6: 3 tập con dataset thật kèm `LICENSE.txt`, ví dụ khuôn mặt `lfw_mini` (chỉ `selection.csv`, `labels.csv`, `README.md`, dựng bằng `scripts/make_examples.py --lfw`) (hoặc `selection.csv` + `scripts/make_examples.py` theo phương án dự phòng); dữ liệu tổng hợp trong `tests/fixtures/` cho test; 9 file config mẫu; `tiny_espcn.py` + script train + trọng số; `make_sr_images.py`; 3 script chuyển đổi dataset; `examples/README.md` | `examples/` | Mọi ví dụ chạy được trên CPU; B5.7 đạt |
| A7.9 | `reproduce <demo> --eval-only`: tải checkpoint bộ nhận dạng đã phát hành bằng `scripts/fetch_checkpoints.py <demo>` (kiểm tra SHA-256), bỏ qua bước train, chạy lại SR, đánh giá và thống kê, so với `expected_results/<demo>.yaml` ở dung sai chặt (accuracy và các metric khớp đến 4 chữ số thập phân trên cùng loại phần cứng); thiếu checkpoint thì mã thoát 3 | Cờ `--eval-only` | B4.5 đạt; thời gian từ vài phút đến khoảng 30 phút tùy demo (phần lớn là chạy SR) |
| A7.10 | Ảnh so sánh trước/sau SR theo đặc tả 2.5: chọn ảnh theo `comparisons.selection` (tất định), vẽ bằng matplotlib, chú thích tiếng Anh, ghi `comparisons/index.csv`; `report.md` nhúng 2 ảnh đầu; `scripts/make_qualitative_figure.py` dùng lại cùng hàm cho Hình 4 của bài báo | `report/comparisons.py` | B1.16 đạt |

File `sr4rec.yaml` do `init` sinh ra phải đúng đặc tả mục 2.4 (đầy đủ comment, enum, khoảng giá trị).

---

## Phần B. Kiểm thử và kiểm chứng

### B1. Unit test (viết cùng lúc với từng module)

| ID | Kiểm tra | Tiêu chí đạt |
|---|---|---|
| B1.1 | Mọi lớp có ở train, val và test; không ảnh nào ở hai tập | Assert |
| B1.2 | Ảnh trùng nội dung (SHA-256) nhưng khác tên file nằm ở hai tập thì bị phát hiện và dừng | Assert |
| B1.3 | `source: column` dùng đúng cột `split`; không có dòng `val` thì chuyển đúng tỉ lệ `val_from_train` từ `train`; `source: column` mà thiếu cột thì dừng; `source: ratios` bỏ qua cột có sẵn | Assert |
| B1.4 | Cùng `split.seed` cho cùng phép chia; seed của bộ nhận dạng không ảnh hưởng tới phép chia | Assert |
| B1.5 | Letterbox với ảnh 1 px, đúng bằng, lớn hơn đầu vào; tỉ lệ khung giữ nguyên | Assert |
| B1.6 | Nguồn thư mục ảnh: báo đúng file thiếu, thừa, sai kích thước | Assert |
| B1.7 | Hệ số trọng số khác `scale` thì dừng với thông báo rõ ràng | Assert |
| B1.8 | Config còn `[CHECK]` (ở `mode`) thì `run` từ chối | Assert |
| B1.9 | Fingerprint có đủ các trường bắt buộc | Assert |
| B1.10 | Schema config: mỗi khóa enum từ chối giá trị ngoài danh sách và thông báo liệt kê đủ giá trị hợp lệ; khóa số từ chối giá trị ngoài khoảng; khóa lạ bị từ chối; một mục SR có cả `weights` và `images` (hoặc không có cái nào) bị từ chối; `tile` đi với `images` bị từ chối | Assert cho từng khóa |
| B1.11 | Tỉ lệ chia: tổng khác 1.0 bị từ chối; giá trị bằng 0 hoặc bằng 1 bị từ chối; với các tỉ lệ khác nhau (ví dụ 0.8/0.1/0.1, 0.6/0.2/0.2), số ảnh mỗi lớp khớp công thức làm tròn ở mục 1.2; lớp không đủ ảnh được liệt kê; số ảnh thực tế in trong report đúng | Assert |
| B1.12 | Đường dẫn trong config được tính từ thư mục chứa `sr4rec.yaml`: chuyển cả thư mục dự án sang vị trí khác vẫn chạy được; `init` không ghi đè `sr4rec.yaml` khi thiếu `--force` | Assert |
| B1.13 | Nguồn `module`: class thiếu `scale`, `scale` sai, không phải `nn.Module`, đầu ra sai kích thước, đầu ra có NaN, file hoặc class không tồn tại: mỗi trường hợp dừng với thông báo nêu đúng lỗi; một mục SR có cả `module` và `images` bị từ chối | Assert |
| B1.14 | `--dry-run` phát hiện mọi lỗi của B1.6, B1.7, B1.13 mà không train; đầu ra khớp mẫu mục 1.6.3 | Assert + snapshot |
| B1.15 | `protocol: matched`: bộ nhận dạng của mỗi SR chỉ nhận ảnh train/val đã qua đúng SR đó (kiểm tra bằng mã băm ảnh đưa vào dataloader); ảnh test của mỗi SR đi qua đúng SR đó; hàng HR train và test trên HR; `fixed_recognizer`: chỉ một bộ nhận dạng cho mỗi (backbone, seed); nguồn `images` thiếu ảnh train/val khi `matched` thì dừng | Assert |
| B1.16 | Ảnh so sánh: đúng số ô và thứ tự ô; đúng số file theo `count` và `selection`; `mixed` chọn đúng tỉ lệ ba nhóm và giống nhau giữa các lần chạy; mọi chữ trên ảnh là tiếng Anh (kiểm tra danh sách chuỗi chú thích); ở `native-lr` không có ô HR và không có PSNR/SSIM | Assert |
| B1.17 | Rank-1 bằng accuracy; Rank-5 và CMC khớp tính tay trên ví dụ nhỏ; Rank-k lớn hơn số lớp ghi `n/a`; cột "same sign" đúng trên ví dụ dựng sẵn; `--dry-run` in đúng số lần train dự kiến cho cả hai protocol | Assert |

Mục tiêu độ phủ code ≥ 80% cho `data`, `lr`, `sr`, `stats`.

### B2. Kiểm chứng so với tham chiếu

| ID | Kiểm chứng | Cách làm | Tiêu chí đạt |
|---|---|---|---|
| B2.1 | Nạp SR qua spandrel khớp code gốc | Chạy script suy luận chính thức của tác giả và SR4Rec trên cùng 20 ảnh | Sai số tuyệt đối trung bình < 1/255 (thang [0,1]); ghi lại sai số lớn nhất |
| B2.2 | PSNR của SwinIR classical và SPAN trên Set5, Set14 (×4); các mô hình real-world (SwinIR real-world, Real-ESRGAN) không có bảng PSNR chuẩn nên chỉ kiểm chứng bằng B2.1 | Kênh Y, cắt viền 4 px | Lệch ≤ 0.05 dB so với bảng trong bài gốc |
| B2.3 | Bicubic kiểu MATLAB | So với ảnh do MATLAB `imresize` tạo (sinh một lần, lưu trong `tests/data/`) | Chênh tối đa 1 mức xám sau khi làm tròn uint8 |
| B2.4 | Thống kê | Bootstrap so với `scipy.stats.bootstrap`; kiểm định hoán vị so với `scipy.stats.permutation_test`; Holm so với `statsmodels.stats.multitest.multipletests` | Cùng seed thì khớp đến 1e-10 (Holm); CI và p lệch dưới 0.01 |
| B2.5 | Accuracy, macro precision, macro recall, macro F1 (kể cả trường hợp có lớp không được dự đoán lần nào); SSIM | Metric nhận dạng so với scikit-learn (`zero_division=0`); SSIM so với code MATLAB `ssim_index.m` của Wang et al. (golden values sinh một lần) | Metric nhận dạng khớp tuyệt đối; SSIM lệch dưới 1e-4 |

Kết quả B2.1–B2.3 đưa vào bài báo thành một bảng kiểm chứng.

### B3. Kiểm tra hợp lý toàn quy trình

| ID | Kiểm tra | Tiêu chí đạt |
|---|---|---|
| B3.1 | "Oracle SR" trả về đúng ảnh HR (chế độ `synthetic`, `protocol: matched`) | Accuracy bằng đúng hàng HR upper bound (cùng seed) |
| B3.2 | Xáo trộn nhãn train | Accuracy test về mức ngẫu nhiên (1/số lớp) trong sai số |
| B3.3 | Train cùng backbone và cấu hình bằng một script timm tối giản bên ngoài tool | Accuracy chênh nằm trong độ dao động qua seed |
| B3.4 | Cố ý chép cùng một ảnh (đổi tên) vào train và test qua cột `split` có sẵn | Tool phát hiện và dừng |

### B4. Tái lập

| ID | Kiểm tra | Tiêu chí đạt |
|---|---|---|
| B4.1 | Chạy cùng config hai lần trên cùng máy | Metric giống nhau từng chữ số |
| B4.2 | Chạy trên máy khác | Nằm trong dung sai của `expected_results` |
| B4.3 | `reproduce quickstart` trong CI | Mã thoát 0 |
| B4.4 | Sửa cố ý một giá trị kỳ vọng | Mã thoát 2 |
| B4.5 | `reproduce <demo> --eval-only` với checkpoint đã phát hành, trên máy khác máy đã train | Khớp log gốc đến 4 chữ số thập phân; thiếu checkpoint thì mã thoát 3 |

### B5. CI, ngôn ngữ và report

| ID | Kiểm tra | Tiêu chí đạt |
|---|---|---|
| B5.1 | `reproduce quickstart` trên CPU runner của GitHub | Dưới 5 phút |
| B5.2 | Ma trận Ubuntu, Windows, macOS; Python 3.10–3.12 | Tất cả xanh |
| B5.3 | Quét ký tự tiếng Việt có dấu trong `src/`, `configs/`, `docs/`, `README.md`, `examples/`, template report, và trong `report.md` do quickstart sinh ra | Không phát hiện |
| B5.4 | Snapshot test `report.md` của quickstart; markdownlint trên report sinh ra | Khớp snapshot; không lỗi lint |
| B5.5 | Mở `report.md` của demo trên GitHub và VS Code, kiểm tra bằng mắt bảng và hình | Hiển thị đúng (checklist thủ công mỗi release) |
| B5.6 | Đồng bộ đặc tả config: mọi khóa trong schema xuất hiện trong file do `init` sinh ra, có đủ `type`, `required`, `default`, `allowed`; `docs/config_reference.md` sinh lại không có thay đổi so với bản trong repo; file do `init` sinh ra nạp lại được mà không lỗi | Test tự động trong CI |
| B5.7 | Chạy toàn bộ tài nguyên mẫu: 8 config mẫu từ `full_reference.yaml` đến `07` (config `08_faces_lfw.yaml` kiểm tra thủ công ở C4.6) (config 02 dùng các trọng số tải được từ GitHub Releases, có cache; trọng số không tải tự động được thì kiểm tra thủ công trước mỗi release), 3 script chuyển đổi dataset trên dữ liệu mẫu, `make_sr_images.py` rồi config 07; mỗi config chạy qua cả `--dry-run` và `run` | Tất cả thành công; thời gian mỗi config dưới 5 phút trên CPU runner |

### B6. Người dùng thử thật (hoãn lại: làm sau khi có bản beta, không nằm trên đường găng của lịch nộp bài)

| ID | Việc | Tiêu chí đạt |
|---|---|---|
| B6.1 | 2–3 người trong lab tự chuẩn bị dataset của họ theo README và chạy tool, không được hướng dẫn trực tiếp | Mỗi người hoàn tất một lần `run` |
| B6.2 | Ghi lại thời gian chuẩn bị dữ liệu, thời gian cài đặt, thời gian đến report đầu tiên, lỗi gặp phải, **chỗ nào trong report khó hiểu** | Phiếu ghi nhận |
| B6.3 | Sửa lỗi, sửa README và template report theo phản hồi | Đóng hết issue trước v0.1.0 |

### B7. Thực nghiệm minh họa cho bài báo (tuần 9–10)

> **Đã thay bằng mục 9 (thiết kế theo EmbedKD, 22/09/2026).** Nội dung dưới đây giữ lại để tham khảo.

**Dataset** (chốt ở A0.5, phải công khai):

| Vai trò | Ứng viên | Ghi chú |
|---|---|---|
| Khuôn mặt (D1) | LFW, những người có từ 20 ảnh trở lên (`synthetic`) | Người dùng tự tải; không đóng gói ảnh; không đưa ảnh mặt vào hình của bài |
| Ảnh tai (D3) | Toàn bộ EarVN1.0, nhận dạng danh tính (`native-lr`) | Cần thầy đồng ý, vì DASA'26 (chưa công bố) cũng dùng EarVN1.0; bài toán và thiết lập phải khác DASA'26 |
| Lĩnh vực khác | CUB-200-2011 (200 loài chim, dùng split chính thức) | Chứng minh tool không chỉ dành cho sinh trắc học |
| Quickstart | `pets_mini` (tập con Oxford-IIIT Pet, mục 1.6.1) | Chạy trong CI |

Mỗi dataset công khai có một script `scripts/prepare_<dataset>.py` chuyển về format 1.2. Đây là script trong repo, không phải tính năng của tool.

**Demo:**

| Demo | Thiết lập | Câu hỏi trả lời | Chi phí ước tính |
|---|---|---|---|
| D1 | LFW (khuôn mặt, từ 20 ảnh mỗi người), `synthetic` ×4, `protocol: matched`; 5 SR (gồm bicubic) + HR × 3 backbone × 3 seed | Thí nghiệm có kiểm soát: SR nào giúp hay hại; PSNR/SSIM có dự đoán được Rank-1 không; ảnh hưởng của loại suy giảm lúc train (cặp SwinIR) | 54 lần train + SR trên toàn bộ dataset; khoảng 6–9 giờ GPU |
| D2 | CUB-200-2011, `synthetic` ×4, `protocol: matched`; 5 SR + HR × 3 backbone × 3 seed | Kết luận có giữ ở lĩnh vực khác không | 54 lần train; khoảng 6–8 giờ GPU |
| D3 | Dataset tai, `native-lr` (ảnh gốc, không hạ mẫu), `protocol: matched`, phân tích theo nhóm kích thước | **Bằng chứng chính** (ảnh nhỏ thật, không có suy giảm mô phỏng): SR giúp hay hại ở kích thước nào | 45 lần train; khoảng 12–16 giờ GPU |
| D5 | Protocol pitfalls (mục 1.7, M1): (a) `matched` so với `fixed_recognizer` trên dữ liệu D2; (b) độ dao động của Δ khi đổi `split.seed` (3 phép chia) so với khác biệt giữa các SR; (c) xếp hạng SR theo PSNR/SSIM so với theo Rank-1 (lấy từ D1) | Các quy tắc tool áp đặt có làm đổi kết luận không | (a) 15 lần train thêm; (b) 2 phép chia × 54 lần train trên CUB giảm còn 1 backbone: 36 lần train; tổng khoảng 8–10 giờ GPU |
| D6 | Kiểm tra độ nhạy siêu tham số (mục 1.7, m3): D2 với learning rate ×0.3 và ×3 cho ResNet-18 | Nhãn kết luận có giữ nguyên khi đổi learning rate không | 2 × 18 lần train; khoảng 3–4 giờ GPU |
| D4 | Latency CPU của 5 SR × 3 backbone | Chi phí triển khai | Khoảng 1 giờ |

Tổng: khoảng 3–4 ngày GPU. Nếu thiếu thời gian, cắt theo thứ tự: D6 → D5(b) → giảm D1 xuống 2 backbone; không giảm số seed và không cắt D3. Sau khi chạy xong, số liệu được đóng băng vào `expected_results/` với dung sai bằng 3 lần độ lệch chuẩn qua seed (tối thiểu 0.2 pp).

---

## Phần C. Release mã nguồn và README

### C1. Cấu trúc repo

```
sr4rec/
├── src/sr4rec/          # source: data, lr, sr, rec, eval, stats, report, cli
├── configs/             # paper demo configs: d1-d4
├── examples/            # sample datasets, sample configs, SR plug-in examples (section 1.6)
├── expected_results/    # reference values and tolerances for `reproduce`
├── scripts/             # build sample subsets, prepare public datasets, make paper figures
├── tests/               # unit, validation, sanity, end-to-end
├── docs/                # dataset format, config reference, report guide, methods
├── README.md
├── CITATION.cff
├── LICENSE
├── DATA_AND_MODEL_LICENSES.md  # licence, source and citation of every dataset, weight file and checkpoint
├── CONTRIBUTING.md             # how to contribute; how an SR model or backbone joins the validated list
├── CODE_OF_CONDUCT.md
├── .github/ISSUE_TEMPLATE/     # bug report, feature request, "add an SR model" templates
├── .github/pull_request_template.md
├── CHANGELOG.md
├── requirements.lock    # exact versions that produced the published results
└── pyproject.toml
```

### C2. README (tiếng Anh, bắt buộc có đủ các mục)

1. **Overview:** SR4Rec làm gì, trả lời câu hỏi gì, dành cho ai; một hình quy trình (chữ tiếng Anh).
2. **Installation:** `pip install sr4rec`; yêu cầu Python ≥ 3.10, PyTorch ≥ 2.2; GPU khuyến nghị; cài từ mã nguồn; kiểm tra bằng `sr4rec reproduce quickstart`; cách tải trước trọng số backbone của timm cho máy không có mạng (`HF_HOME`).
3. **Project layout:** cây thư mục dự án ở mục 1.5 (`sr4rec.yaml`, `data/`, `weights/`, `sr_images/`, `runs/`), mỗi thư mục chứa gì, ai tạo ra (người dùng hay tool), và quy tắc đường dẫn tương đối tính từ `sr4rec.yaml`.
4. **Quick start (3 steps):**
   ```bash
   cd my_project
   sr4rec init data/my_dataset/   # 1. validate the dataset, write ./sr4rec.yaml
   # 2. edit sr4rec.yaml: put your SR weights in weights/ and list them,
   #    set the split ratios if needed, confirm every [CHECK] line
   sr4rec run sr4rec.yaml         # 3. run; then open runs/<run_name>/report.md
   ```
5. **Preparing your dataset:** đặc tả format 1.2 đầy đủ; vị trí đặt dataset (`data/<dataset_name>/`); cách khai báo phép chia (dùng cột `split` hoặc nhập tỉ lệ train/val/test), quy tắc làm tròn theo lớp và số ảnh tối thiểu mỗi lớp; hai đoạn code mẫu chuyển dataset:
   ```python
   # Folder-per-label layout (images/<label>/*.jpg) -> labels.csv
   from pathlib import Path
   import pandas as pd

   root = Path("data/my_dataset/images")
   exts = {".jpg", ".jpeg", ".png", ".bmp"}
   rows = [{"path": p.relative_to(root).as_posix(), "label": p.parent.name}
           for p in sorted(root.rglob("*")) if p.suffix.lower() in exts]
   pd.DataFrame(rows).to_csv("data/my_dataset/labels.csv", index=False)
   ```
   ```python
   # Identity encoded in file names (e.g. 017_s1_03.jpg -> person 017) -> labels.csv
   from pathlib import Path
   import pandas as pd

   root = Path("data/my_dataset/images")
   rows = []
   for p in sorted(root.glob("*.jpg")):
       person = p.stem.split("_")[0]
       rows.append({"path": p.name, "label": person})
   pd.DataFrame(rows).to_csv("data/my_dataset/labels.csv", index=False)
   ```
6. **Adding SR models:** bảng chọn cách (mục 1.6.3); bảng link tải chính thức, SHA-256 và **loại suy giảm lúc train** của 4 trọng số kiểm chứng; hướng dẫn từng bước cho cả 3 cách (`weights`, `module`, `images`), mỗi cách kèm đoạn YAML và ví dụ chạy được trong `examples/`; giao diện bắt buộc của class mô hình; cách kiểm tra bằng `--dry-run`; lưu ý an toàn khi chạy code của người dùng.
7. **Examples:** danh sách tài nguyên mẫu trong `examples/` (dataset thú cưng, tai, khuôn mặt; config; mô hình SR mẫu), kèm lưu ý quyền riêng tư cho ví dụ khuôn mặt, mỗi mục một dòng lệnh chạy và thời gian dự kiến.
8. **Configuration reference:** bảng mọi khóa của `sr4rec.yaml` với kiểu, bắt buộc hay không, giá trị mặc định và giá trị hợp lệ (enum hoặc khoảng); dẫn tới `docs/config_reference.md` (sinh tự động từ schema).
9. **Reading the report:** giải thích từng mục của `report.md`, quy tắc kết luận, cách đọc hai biểu đồ; nêu rõ giới hạn của chế độ `native-lr` và cảnh báo lệch miền trọng số.
10. **Output files:** cấu trúc `runs/<run_name>/`, ý nghĩa từng file và từng cột CSV.
11. **Reproducing the paper:** `python scripts/prepare_<dataset>.py --out data/<dataset>`, đặt trọng số vào `weights/`; mức 1: `python scripts/fetch_checkpoints.py d1` rồi `sr4rec reproduce d1 --eval-only` (không train); mức 2: `sr4rec reproduce d1` … `d4` (train lại đầy đủ); thời gian dự kiến; ý nghĩa mã thoát 0/2/3.
12. **FAQ:** hết bộ nhớ GPU (`tile`), spandrel không nhận ra kiến trúc (chuyển sang cách 2 hoặc 3), hệ số không khớp, dataset rất nhỏ, kết quả khác giữa các máy.
13. **Limitations** và **Roadmap** (trích từ mục 6); **Contributing and maintenance** (dẫn tới `CONTRIBUTING.md`, chính sách phiên bản); **Data and model licences** (dẫn tới `DATA_AND_MODEL_LICENSES.md`).
14. **Citation, license, acknowledgements:** BibTeX, DOI Zenodo, giấy phép của SR4Rec và của từng mô hình, trọng số, dataset bên thứ ba.

### C3. `docs/`

Chỉ gồm vài file Markdown, không dựng website:
- `preparing_dataset.md`: hướng dẫn chuyển TinyFace sang format 1.2 (mục 1.6.1); đặc tả đầy đủ format dataset, cách khai báo phép chia, cấu trúc thư mục dự án, các script chuyển đổi và lỗi thường gặp (mục 1.2, 1.5, 1.6.4).
- `adding_sr_models.md`: hướng dẫn từng bước cho 3 cách đưa mô hình SR vào, giao diện bắt buộc của class, cách dùng `--dry-run` (mục 1.6.3).
- `config_reference.md`: mọi khóa config, sinh tự động từ schema (A1.7), không sửa tay.
- `report_guide.md`: cách đọc report và quy tắc kết luận.
- `methods.md`: quy trình xử lý, cài đặt thống kê, quy tắc phương pháp 1.3.
- `reference_environment.md`: phần cứng và phiên bản đã tạo ra kết quả trong bài.

### C4. Phát hành

| ID | Việc | Hoàn thành khi |
|---|---|---|
| C4.1 | Semantic Versioning; `CHANGELOG.md`; chính sách phiên bản ghi trong `CONTRIBUTING.md` (thay đổi không tương thích chỉ ở phiên bản major; tính năng bị bỏ được báo trước ít nhất một phiên bản minor) | Có mục cho mỗi phiên bản |
| C4.2 | Beta `0.1.0b1` lên TestPyPI rồi PyPI (cuối tuần 8) | Cài được trên máy sạch |
| C4.3 | Chính thức `0.1.0` sau khi sửa lỗi từ các demo (và từ B6 nếu đã làm) (tuần 11) | CI xanh; `reproduce` đạt |
| C4.4 | Kết nối Zenodo, DOI cho `v0.1.0` | DOI hoạt động |
| C4.5 | `CITATION.cff` hợp lệ | GitHub hiện "Cite this repository" |
| C4.6 | Kiểm tra cuối trên máy sạch: cài đặt, quickstart, một demo đầy đủ, dựng `lfw_mini` bằng `scripts/make_examples.py` và chạy `08_faces_lfw.yaml` | Tất cả đạt |
| C4.7 | Phát hành checkpoint bộ nhận dạng của D1–D3 (mọi SR × 3 backbone × 3 seed, khoảng 150 file, dự kiến 10–15 GB) lên Zenodo, kèm file danh sách SHA-256 và `LICENSE` ghi rõ checkpoint kế thừa điều khoản sử dụng của dataset đã dùng để train (chỉ dùng cho nghiên cứu, phi thương mại); checkpoint của dataset chưa được phép phân phối thì không phát hành, và `--eval-only` của demo đó được ghi là không khả dụng | Checkpoint tải được bằng `fetch_checkpoints.py`; B4.5 đạt |
| C4.8 | Tài liệu bền vững và giấy phép (mục 1.7, m4, m5): `DATA_AND_MODEL_LICENSES.md`, `CONTRIBUTING.md` (gồm tiêu chuẩn để một SR hoặc backbone vào danh sách kiểm chứng: vượt B2.1 và chạy trong CI), `CODE_OF_CONDUCT.md`, mẫu issue và PR; badge CI và độ phủ test trong README | Có đủ file; badge hiển thị đúng |

---

## Phần D. Viết bài theo định dạng SoftwareX

### D1. Chuẩn bị

| ID | Việc | Ghi chú |
|---|---|---|
| D1.1 | Tải template LaTeX chính thức (Original Software Publication), đọc lại guide for authors bản hiện hành | Không đổi định dạng template |
| D1.2 | Ràng buộc: tối đa 4000 từ (tính abstract, nội dung, chú thích hình, footnote; không tính tiêu đề, tác giả, tài liệu tham khảo, bảng metadata); tối đa 6 hình | Kiểm tra lại trong guide khi viết |
| D1.3 | Link repo trỏ vào tag `v0.1.0` | Ví dụ `.../tree/v0.1.0` |
| D1.4 | Tìm và đọc tài liệu cho motivation: nghiên cứu về tác động của SR lên nhận dạng (khuôn mặt, biển số, viễn thám), BasicSR, KAIR, timm, pyiqa, opensr-test, spandrel | Chỉ trích dẫn nguồn đã đọc |

### D2. Nguyên tắc: bài báo trình bày kết quả, README là nơi hướng dẫn

Bài báo theo đúng cách trình bày của EmbedKD:
- Bài báo **trình bày phần mềm và kết quả đo được** bằng phần mềm: vấn đề, thiết kế, quy tắc phương pháp, kiểm chứng tính đúng, kết quả các demo (kể cả kết quả âm tính), tác động, hạn chế.
- Bài báo **không phải tài liệu hướng dẫn**. Mọi hướng dẫn từng bước (cài đặt, chuẩn bị dataset, viết config, đưa mô hình SR vào, đọc report) nằm trong README và `docs/` của repo. Bài chỉ nhắc một câu và dẫn tới README.
- Chỉ giữ lại những gì EmbedKD cũng giữ: một đoạn code mẫu ngắn (mục 2.3, yêu cầu của template), một câu về quickstart, và transcript console trong phụ lục.
- Hạn chế và kết quả âm tính được viết thẳng, không giấu (theo tinh thần "a limit we report rather than omit").

### D2b. Cấu trúc bài (toàn bộ bằng tiếng Anh)

| Mục | Nội dung | Số từ |
|---|---|---|
| Title, Abstract, Keywords | Vấn đề; SR4Rec làm gì; con số chính của các demo; câu "every headline number reproduces from one command" | 150–200 |
| Required Metadata | Bảng 1 Code metadata (mục D4) | không tính |
| 1. Motivation and significance | SR được dùng làm tiền xử lý cho nhận dạng danh tính trên ảnh chất lượng thấp; PSNR/SSIM không trả lời được câu hỏi nhận dạng, lợi ích hạ nguồn còn tranh cãi; công cụ SR và công cụ nhận dạng tách rời; Bảng 2 so sánh chức năng, kèm đoạn giải thích vì sao đây không phải một plugin của BasicSR (M1); công trình trước của nhóm (DASA'26 nếu đã được chấp nhận); nêu rõ SR4Rec không đề xuất phương pháp SR mới; kết thúc bằng các mục tiêu mà tool đặt ra, các phần sau bám theo | 750–850 |
| 2. Software description | 2.1 Software architecture (Hình 1) và các quyết định kiến trúc chính; 2.2 Software functionalities (dữ liệu và hai chế độ, ba nguồn SR, quy tắc phương pháp, thống kê, đầu ra và tái lập); 2.3 Sample code snippet (giao diện class SR của cách `module`); 2.4 Technical limitations (chỉ nhận dạng tập đóng, không có xác thực và tập mở; suy giảm tổng hợp chỉ là bicubic; siêu tham số cố định; một GPU) | 1100–1200 |
| 3. Illustrative examples | Một đoạn quickstart (dẫn tới README và Phụ lục B); experimental setup, trong đó ghi rõ loại suy giảm lúc train của từng SR (M2); kiểm chứng tính đúng (Bảng 3); **D3 ảnh nhỏ tự nhiên là bằng chứng chính** (Hình 3); D1 thí nghiệm có kiểm soát, kèm cặp SwinIR classical/real-world (Hình 2, Bảng 4); D5 protocol pitfalls (M1); ví dụ định tính (Hình 4); D2 và tổng hợp các demo (Bảng 5); deployment (Bảng 6); reproduction ở hai mức: `--eval-only` với checkpoint đã phát hành (thời gian và số chữ số thập phân khớp với log gốc) và train lại đầy đủ (thời gian trên máy tham chiếu) | 1000–1100 |
| 4. Impact | Các câu hỏi trước đây phải thử mò nay trả lời được bằng đo đạc (gạch đầu dòng, mỗi dòng gắn với một kết quả của mục 3); cho thực hành hằng ngày, kèm số liệu công sức tiết kiệm được (M4); việc dùng tool trong các nghiên cứu của nhóm (M4); cho cộng đồng (kết quả kỳ vọng có dung sai, DOI Zenodo, chính sách phiên bản, cách đóng góp, roadmap; m5) | 400–500 |
| 5. Conclusions | Tóm tắt kết quả, nêu cả kết quả âm tính | 150 |
| CRediT, Declaration of competing interest, Data availability | Theo mẫu | không tính (kiểm tra lại guide) |
| Appendix A | Config đầy đủ của demo D1 | không tính (kiểm tra lại guide) |
| Appendix B | Transcript console: `init`, `run --dry-run`, `run`, `reproduce` | như trên |
| Appendix C | Bảng đầy đủ của D1 (CI 95%, p thô và p đã hiệu chỉnh Holm, same sign); bảng chi tiết theo nhóm kích thước; chi tiết D5; kiểm tra độ nhạy D6 (m3); chi tiết kiểm chứng | như trên |
| References | | không tính |

Tổng mục tiêu phần chính: 3600–3900 từ. D5 và D6 chỉ 2–3 câu mỗi demo trong phần chính, chi tiết ở Phụ lục C (mục 1.8, điểm 4).

### D3. Hình và bảng (chữ trong mọi hình bằng tiếng Anh; không có ảnh khuôn mặt)

> **Đã thay bằng mục 9.** Nội dung dưới đây giữ lại để tham khảo.

Theo EmbedKD, ngoài sơ đồ kiến trúc, **mọi hình đều là kết quả**. Không dùng hình để hướng dẫn và không dùng ảnh chụp màn hình report trong bài; report được trình bày ở README.

| Hình | Nội dung | Nguồn |
|---|---|---|
| 1 | Kiến trúc: vòng đời `init → run → report/reproduce`, class `Run` dùng chung cho CLI và API, các module, ba nguồn SR (`weights` / `module` / `images`), cache, fingerprint | Vẽ (TikZ hoặc draw.io) |
| 2 | D1: hai panel, PSNR so với Rank-1 và SSIM so với Rank-1; mỗi điểm là một cặp SR × backbone; ký hiệu điểm phân biệt SR train cho suy giảm bicubic và suy giảm thực tế | `scripts/make_paper_assets.py` |
| 3 | D3 (bằng chứng chính): Rank-1 theo 4 nhóm kích thước ảnh (native LR), dải CI 95% | `scripts/make_paper_assets.py` |
| 4 | Ví dụ định tính (cùng hàm vẽ với `comparisons/`, mục 2.5): ảnh LR, bicubic, các SR, HR; viền màu cho nhận dạng đúng hoặc sai; một nửa là ảnh SR sửa đúng, một nửa là ảnh SR làm sai, chọn theo quy tắc cố định chứ không chọn tay; chú thích ghi tổng số ảnh sửa đúng và làm sai | `scripts/make_qualitative_figure.py` |

| Bảng | Nội dung |
|---|---|
| 1 | Code metadata |
| 2 | So sánh chức năng có sẵn khi cài đặt với BasicSR, KAIR, timm, pyiqa, opensr-test (ghi chú như EmbedKD: mọi thành phần đều có thể dựng trong các framework khác; đóng góp là quy trình đã kiểm chứng) |
| 3 | Kiểm chứng tính đúng (B2): wrapper SR so với code gốc, PSNR so với bài gốc, bicubic so với MATLAB, thống kê so với SciPy/statsmodels |
| 4 | Kết quả chính D1, hai phần: (a) chất lượng ảnh theo SR, kèm loại suy giảm lúc train: PSNR, SSIM; (b) nhận dạng theo backbone × SR: Rank-1, Rank-5, macro precision, macro recall, macro F1 (mean ± sd), Δ Rank-1 so với bicubic, kết luận. CI, p và same sign đầy đủ nằm ở Phụ lục C |
| 5 | Tổng hợp các demo D1, D2, D3 và D5: dataset, chế độ, protocol, SR tốt nhất, Δ, kết luận, **GPU-giờ thực tế** (m2); các dòng D5 cho thấy kết luận thay đổi thế nào khi đổi protocol hoặc phép chia (M1) |
| 6 | Deployment D4: latency SR, bộ nhận dạng và cả chuỗi (median, p95), CPU và số luồng |

Mọi hình và bảng số liệu sinh bằng script trong repo; chú thích ghi tên script. Các số liệu lấy từ `expected_results/` bằng script, không chép tay.

### D4. Code metadata (theo mẫu tạp chí)

| Nr. | Code metadata description | Value |
|---|---|---|
| C1 | Current code version | v0.1.0 |
| C2 | Permanent link to code/repository | https://github.com/<account>/sr4rec/tree/v0.1.0 |
| C3 | Permanent link to reproducible capsule | Zenodo DOI |
| C4 | Legal code license | MIT (chốt ở A0.4) |
| C5 | Code versioning system used | git |
| C6 | Software code languages, tools and services used | Python, PyTorch, timm, spandrel |
| C7 | Compilation requirements, operating environments and dependencies | Python ≥ 3.10; PyTorch ≥ 2.2; Linux, Windows, macOS; exact versions in `requirements.lock` |
| C8 | Link to developer documentation/manual | README and `docs/` |
| C9 | Support email for questions | Email tác giả liên hệ |

Nếu mẫu hiện hành yêu cầu thêm bảng Software metadata, điền cùng thông tin kèm link PyPI.

### D5. Quy trình viết

| ID | Việc | Tuần |
|---|---|---|
| D5.1 | Dàn ý chi tiết từng mục, gửi thầy duyệt | 12 |
| D5.2 | Bản nháp 1 (trình bày kết quả, không viết hướng dẫn; mục D2) theo thứ tự: Software description → Illustrative examples → Motivation → Impact → Abstract → Conclusions | 12–13 |
| D5.3 | Đối chiếu mọi con số trong bài với `expected_results/` bằng script | 13 |
| D5.4 | Đếm từ bằng `texcount`; kiểm tra số hình | 13 |
| D5.5 | Một người ngoài nhóm đọc: có hiểu tool làm gì và cài được từ bài không | 13 |
| D5.6 | Thầy review, sửa bản cuối | 14 |
| D5.7 | Nộp qua Editorial Manager | 14 |

### D6. Checklist trước khi nộp

- [ ] Đúng template, không đổi định dạng
- [ ] ≤ 4000 từ, ≤ 6 hình
- [ ] Repo công khai; tag `v0.1.0` tồn tại; link trong bài mở được
- [ ] DOI Zenodo hoạt động
- [ ] `pip install sr4rec==0.1.0` cài được trên máy sạch
- [ ] `sr4rec reproduce quickstart` đạt; `reproduce --eval-only` đạt cho mọi demo có checkpoint phát hành; ít nhất một demo train lại đầy đủ đạt trên máy khác
- [ ] Mọi con số trong bài khớp `expected_results/`
- [ ] Mọi hình số liệu có script sinh ra trong repo
- [ ] Không có tiếng Việt trong bài, hình, bảng, repo, README, docs, comment code, đầu ra của tool (B5.3 xanh)
- [ ] Không có kết quả chưa công bố của DASA'26 hay bài NCA (hoặc đã được chấp nhận và trích dẫn đúng)
- [ ] Giấy phép của mọi mô hình, trọng số, dataset đã ghi nhận
- [ ] CRediT, competing interests, data availability đầy đủ
- [ ] Thầy đã duyệt bản cuối

---

## 3. Lịch trình

| Tuần | Thời gian | Công việc | Mốc |
|---|---|---|---|
| 1 | 05–09/10/2026 | A0, A1 (gồm schema config, bước CI quét tiếng Việt) + B1.10 | Chốt tên, giấy phép, dataset; spandrel nạp được 4 file |
| 2 | 12–16/10 | A2 + B1.1–B1.4, B1.11 | Module `data` xong |
| 3 | 19–23/10 | A3, A4.1–A4.3 + B2.3, B1.5 | |
| 4 | 26–30/10 | A4.4–A4.7 + B2.1, B2.2, B1.6–B1.7, B1.13 | Toàn bộ SR hoạt động |
| 5 | 02–06/11 | A5 | |
| 6 | 09–13/11 | A6 (gồm Rank-5, CMC, same sign) + B2.4, B2.5, B3, B1.17 | Chạy trọn quy trình lần đầu |
| 7 | 16–20/11 | A7 (gồm A7.8 tài nguyên mẫu, A7.9 `--eval-only`) + B1.8–B1.9, B1.12, B1.14, B5.4, B5.6, B5.7 | Đủ tính năng v0.1 |
| 8 | 23–27/11 | B4, B5, C1–C3, C4.1–C4.2 | **Beta 0.1.0b1** |
| 9 | 30/11–04/12 | B7 (D3 trước, rồi D1, D2) | |
| 10 | 07–11/12 | B7 (D4, D5, D6), đo công sức tiết kiệm (M4), sửa lỗi | Kết quả demo đầy đủ |
| 11 | 14–18/12 | Đóng băng kết quả, phát hành checkpoint (C4.7), B4.5, C4.3–C4.6, C4.8 | **Release v0.1.0 + DOI** |
| 12 | 21–25/12 | D1, D5.1–D5.2 | Dàn ý được duyệt |
| 13 | 28/12/2026–01/01/2027 | D5.2–D5.5 (tuần nghỉ lễ, làm nhẹ) | Bản nháp hoàn chỉnh |
| 14 | 04–08/01/2027 | D5.6–D5.7, D6 | **Nộp bài** |
| Dự phòng | 11–22/01/2027 | Xử lý chậm trễ | Trước Tết |

---

## 4. Rủi ro và phương án

| Rủi ro | Khả năng | Phương án |
|---|---|---|
| Phát hiện công cụ tương tự ở A0.1 | Trung bình | Làm rõ khác biệt (quy tắc phương pháp, thống kê theo ảnh, report đọc được ngay); nếu trùng hoàn toàn thì dừng và chọn hướng khác |
| Spandrel không nạp được một trong 4 file trọng số | Thấp | Thay bằng file hoặc mô hình khác cùng họ mà spandrel hỗ trợ; ghi rõ trong bài |
| Nạp qua spandrel không khớp code gốc (B2.1) | Thấp | Báo lỗi cho spandrel; tạm dùng nguồn thư mục ảnh sinh từ code gốc cho demo |
| Không tất định hoàn toàn trên GPU | Trung bình | Chế độ tất định; công bố dung sai; ghi rõ khớp từng chữ số chỉ đảm bảo trên cùng máy |
| Kết quả demo không có khác biệt nào | Trung bình | Vẫn là kết quả hợp lệ; bài SoftwareX đánh giá tool, không đòi SR phải giúp |
| Ví dụ khuôn mặt bị đặt câu hỏi về quyền riêng tư | Thấp | Không đóng gói ảnh; lưu ý quyền riêng tư trong README; không dùng ảnh mặt trong bài báo; nếu vẫn bị phản đối thì bỏ ví dụ `lfw_mini` mà không ảnh hưởng phần còn lại |
| Checkpoint train trên dataset có điều khoản hạn chế không được phép phát hành | Trung bình | Hỏi cùng lúc với A0.5; nếu không được phép thì `--eval-only` chỉ khả dụng cho demo có dataset cho phép, và bài ghi rõ điều này |
| Không được phép đóng gói ảnh của dataset mẫu | Trung bình | Phương án dự phòng 1.6.1: repo chỉ chứa `selection.csv` và `labels.csv`, người dùng tự tải dataset gốc rồi dựng lại đúng tập con bằng `scripts/make_examples.py` |
| Dataset tai công khai nhỏ, CI rộng | Trung bình | Báo cáo trung thực; D2 trên CUB có nhiều ảnh test hơn |
| Thời gian GPU tăng do `protocol: matched` | Trung bình | Cache SR và checkpoint; chạy demo qua đêm; nếu thiếu thời gian thì giảm số backbone của D1, D3 trước (không giảm seed) |
| Chậm tiến độ do bài NCA và DASA'26 | Cao | 2 tuần dự phòng; cắt D4 trước, không cắt kiểm thử |
| Người dùng thử thấy report khó hiểu | Trung bình | B6 đã hoãn; trước v0.1.0 ít nhất nhờ 1–2 người trong nhóm đọc thử report của quickstart; sửa template ở bản vá nếu có phản hồi sau này |

---

## 5. Những gì đã loại khỏi v0.1.0 (để kế hoạch không phình to)

Các mục dưới đây từng được thảo luận nhưng **không làm** trong v0.1.0. Không viết code, không viết tài liệu, không nhắc trong README ngoài mục Roadmap.

| Đã loại | Lý do |
|---|---|
| Tự nhận diện cấu trúc dataset, adapter, mẫu tên file | Người dùng tự chuẩn bị theo format quy định |
| Chế độ `cross-resolution` | Hai chế độ đã trả lời câu hỏi chính |
| Hạ mẫu theo kích thước đích, preset suy giảm `realistic`, nhiều mức trong một lần chạy | Một hệ số mỗi lần chạy là đủ và chuẩn |
| Chính sách hệ số `adaptive`, `threshold`, `cascade`, `upscale-then-resize` | Bắt buộc hệ số SR bằng hệ số hạ mẫu |
| Đưa SR qua file ONNX; registry dạng decorator; lệnh `fetch` tự tải trọng số | Ba cách `weights`, `module`, `images` đã bao phủ mọi trường hợp |
| Xuất ONNX, kiểm tra parity, đo trên mobile | Rủi ro kỹ thuật cao (SwinIR), không cần cho câu hỏi chính |
| NIQE, MUSIQ; t-test qua seed, Cohen's dz, McNemar | Một bộ thống kê đã kiểm chứng là đủ |
| Các lệnh từng bước (`manifest`, `diagnose`, `enhance`, `fit`, `eval`, `deploy`, `export-lr`) | Ba lệnh `init`, `run`, `reproduce` là đủ |
| Report HTML, website tài liệu | Report Markdown và vài file `docs/` là đủ |

---

## 6. Future work (ghi vào bài báo và mục Roadmap của README)

Xếp theo mức ưu tiên dự kiến cho các phiên bản sau:

1. **Phân loại thuộc tính** (ví dụ giới tính), với phép chia không trùng người theo `subject_id`.
2. **Nhận dạng tập mở và xác thực** (gallery/probe bằng embedding; Rank-k, CMC, EER, TAR@FAR), là kịch bản thực tế của sinh trắc học.
3. **Chế độ `cross-resolution`:** HR để đăng ký, LR thật để truy vấn.
4. **Suy giảm thực tế và quét độ phân giải:** preset blur + noise + JPEG; hạ mẫu theo kích thước đích và nhiều mức trong một lần chạy, để vẽ đường cong accuracy theo độ phân giải.
5. **Linh hoạt hệ số SR:** cho phép SR có hệ số khác hệ số hạ mẫu, với bước resize được ghi rõ.
6. **Triển khai:** xuất ONNX cho chuỗi SR + nhận dạng, kiểm tra parity, đo latency trên thiết bị di động.
7. **Mở rộng nguồn SR:** file ONNX, SR dựa trên diffusion, video SR.
8. **Metric không cần tham chiếu** (NIQE, MUSIQ qua pyiqa) cho chế độ `native-lr`.
9. **Report HTML tương tác** và so sánh nhiều lần chạy trong một report.
10. **Huấn luyện nhiều GPU** cho dataset lớn.

---

## 7. Việc cần thầy/nhóm quyết định trước tuần 1

1. Thứ tự công bố DASA'26, NCA và SoftwareX; bài SoftwareX có được tính vào yêu cầu công bố của chương trình tiến sĩ không.
2. Danh sách và thứ tự tác giả.
3. Dùng EarVN1.0 (toàn bộ, `native-lr`) cho D3 và LFW cho D1; thiết lập D3 phải khác DASA'26.
4. Giấy phép cho SR4Rec: MIT hay Apache 2.0.
5. Văn bản cho phép đóng gói tập con EarVN1.0 (`earvn_mini`) vào repo và phát hành checkpoint train trên EarVN1.0; nếu không, dùng phương án dự phòng ở mục 1.6.1 và không phát hành checkpoint đó.

---

## 8. Trạng thái triển khai (bản mã nguồn v0.1.0.dev0, 22/09/2026)

**Đã có trong `sr4rec.zip`:** toàn bộ phần A (A1–A7) trừ các việc cần dữ liệu thật hoặc GPU; bộ test B1, B2.3–B2.5, B3.1, B3.4, B4.1, B5.3, B5.6 (120 test, chạy khoảng 35 giây trên CPU); README đủ 14 mục; `docs/` đủ 6 file; `examples/` đủ 9 config; CI, release workflow, CITATION.cff, codemeta.json, .zenodo.json, CONTRIBUTING, CODE_OF_CONDUCT, DATA_AND_MODEL_LICENSES, CHANGELOG.

**Khác với kế hoạch (có chủ đích):**
- Config demo và `expected_results` nằm trong package (`src/sr4rec/demos/`, `demos/expected/`) thay vì `configs/` và `expected_results/` ở gốc repo, để `sr4rec reproduce` chạy được sau `pip install`. Demo: quickstart, d1_lfw, d2_cub, d3_earvn, d5a_cub_fixed, d5b_cub_split1/2, d6_cub_lr_low/high (D4 là phần latency có sẵn trong mọi lần chạy).
- Không đóng gói ảnh của dataset mẫu nào (kể cả Oxford-IIIT Pet): `scripts/make_examples.py` dựng lại tập con theo quy tắc cố định và ghi `selection.csv` (SHA-256 ảnh gốc, và SHA-256 ảnh đầu ra cho pets_mini). `pets_mini` lưu PNG để không phụ thuộc bộ mã hóa JPEG. `earvn_mini` không còn tiêu chí 10 nam/10 nữ (script không biết giới tính); chọn 20 người đầu tiên có từ 20 ảnh.
- `pyproject` yêu cầu PyTorch ≥ 2.3 (`torch.amp.GradScaler`).
- `sr4rec init` chạy luôn phép chia mặc định để báo lớp quá nhỏ và ảnh trùng; nếu lỗi vẫn ghi config và in cảnh báo.
- Ví dụ 05 không dùng `tiny_espcn` (trọng số train trên tập train chính thức của pets_mini, phép chia mới sẽ gây rò rỉ).

**Còn phải làm trên máy có mạng/GPU (trước khi phát hành):**
1. A0.4: tải SPAN x4, ghi SHA-256 vào `src/sr4rec/sr/validated.py`, README, `docs/adding_sr_models.md`; chạy B2.1, B2.2.
2. Tải Oxford-IIIT Pet, EarVN1.0, LFW; chạy `scripts/make_examples.py` một lần và commit các `selection.csv`, `labels.csv`; chạy `examples/sr_models/train_tiny_espcn.py`, commit `tiny_espcn_x4_pets.pth`; điền cache mẫu cho job `examples` của CI.
3. B2.3: thay `tests/data/resize_golden.npz` (hiện sinh bằng BasicSR) bằng giá trị MATLAB.
4. B7: chạy D1–D6, `scripts/freeze_expected.py` cho từng demo, `scripts/export_checkpoints.py` + điền `scripts/checkpoints_manifest.json`, điền `docs/reference_environment.md`.
5. C4: thay `OWNER` trong README, CITATION.cff, codemeta.json bằng tài khoản GitHub thật; xác nhận thứ tự họ tên và ORCID của tác giả; tạo DOI Zenodo.

**Cập nhật 22/09/2026 — bản thảo bài báo:** đã có `paper/` trong repo (main.tex theo elsarticle v3.4c, cấu trúc SoftwareX, bảng code metadata, Hình 1 TikZ, references.bib, validation.yaml). Motivation và Software description đã viết nháp (khoảng 2.100 từ phần chính tính cả ghi chú TODO); Illustrative examples, Impact, Conclusions còn khung chờ số liệu thật. Mọi hình/bảng/số liệu sinh bằng `scripts/make_paper_assets.py` từ thư mục run (đã chạy thử trên dữ liệu giả để kiểm tra biên dịch, không dùng số liệu đó). Thứ tự hình theo lần nhắc đầu tiên trong bài: Hình 2 = D3 theo kích thước (bằng chứng chính), Hình 3 = D1 PSNR/SSIM so với Rank-1, Hình 4 = ví dụ định tính D3. Bảng D1 tách thành hai bảng (chất lượng ảnh; nhận dạng).


---

## 9. Thiết kế thực nghiệm cuối cùng (theo EmbedKD, thay thế B7 và D3)

Theo cách EmbedKD làm: ít thí nghiệm, mỗi thí nghiệm trả lời đúng một câu hỏi; một demo chính 3 seed có bảng số liệu; một thí nghiệm có kiểm soát; một bảng tổng hợp các demo (demo chạy 1 lần thì không kết luận so sánh); một hình định tính; latency; đoạn tái lập hai mức; kiểm chứng độ đúng nằm ở Phụ lục C.

| Demo | Thiết lập | Câu hỏi | Mục trong bài | Số lần train | Ước tính |
|---|---|---|---|---|---|
| quickstart | pets_mini, CPU | cài và chạy được | Quickstart | 3 | ~5 phút CPU |
| **D1** `d1_earvn` | EarVN1.0, native-lr ×4, matched, bicubic + 4 SR, ResNet-18, 3 seed | SR có giúp trên ảnh nhỏ thật không, ở kích thước nào | Bảng D1, Hình 2 (Δ theo kích thước), Hình 4 (định tính), Bảng latency | 15 | ~5–7 h GPU |
| D1-fixed `d1_earvn_fixed` | như D1, protocol fixed_recognizer | protocol làm đổi kết luận thế nào (góp ý M1) | 1 đoạn + bảng tổng hợp | 3 | ~1 h |
| **D2** `d2_lfw` | LFW (≥ 20 ảnh/người), synthetic ×4, matched, ResNet-18, 3 seed | PSNR/SSIM có dự đoán được Rank-1 không; cặp SwinIR classical/real-world tách ảnh hưởng của loại suy giảm | Bảng D2, Hình 3 | 18 | ~3–4 h |
| D3 `d3_cub` | CUB-200-2011, split chính thức, synthetic ×4, ResNet-18, 1 seed | quy trình trên lĩnh vực khác (không kết luận so sánh) | bảng tổng hợp | 6 | ~1–2 h |
| Kiểm chứng | `scripts/check_sr_fidelity.py` trên Set5/Set14; bộ test | nạp SR và PSNR/SSIM đúng | Phụ lục C | 0 | < 1 h |

**Tổng: khoảng 10–14 giờ GPU** (EmbedKD: khoảng 11 giờ). Đã bỏ: D2 CUB 3 seed × 3 backbone, D5b (đổi split seed), D6 (độ nhạy learning rate), ba backbone trong demo chính. Các backbone MobileNetV3-Small và ConvNeXt-Tiny vẫn là backbone được kiểm chứng của tool nhưng không có trong bài.

**Hình (4, như EmbedKD):** 1 kiến trúc; 2 D1 Δ Rank-1 theo kích thước ảnh LR, CI 95%; 3 D2 PSNR/SSIM so với Rank-1; 4 D1 ví dụ định tính (ảnh tai, không có ảnh mặt).
**Bảng:** 1 code metadata; 2 so sánh chức năng; D1 kết quả chính; D2 chất lượng ảnh và nhận dạng; tổng hợp các demo; latency CPU; Phụ lục C: kiểm chứng độ đúng, D1 theo kích thước.

**Đã kiểm chứng trong môi trường này (22/09/2026):** SwinIR-M ×4 classical qua SR4Rec trên Set5 (LR bicubic của bộ test): PSNR 32,75 dB, SSIM 0,9021; bài gốc 32,72 / 0,9021 → đạt (lệch 0,03 dB ≤ 0,05 dB). Hàm bicubic của SR4Rec khớp bản BasicSR đến 1e-5; so với file LR có sẵn trong Set5 của repo SwinIR lệch tối đa 1–2 mức xám ở khoảng 10% điểm ảnh (các file đó có thể không sinh bằng MATLAB), nên B2.3 vẫn cần chạy MATLAB.

**Thứ tự chạy:** check_sr_fidelity (Set5, Set14; cần SPAN) → D1 → D1-fixed → D2 → D3 → freeze_expected → export checkpoint D1 → reproduce --eval-only trên máy khác → make_paper_assets → viết mục 3–5.
