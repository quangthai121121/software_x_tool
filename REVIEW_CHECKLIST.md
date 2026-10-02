# Checklist sửa bài theo góp ý (gop_y_sr4rec_softwarex.md)

Cập nhật lần cuối: 2026-09-28. Đã lọc theo phản biện — bỏ A1 (đã xong: chuyển sang
`pip install -e .`, không cần PyPI) và A6 (đã tự resolve, DOI trả HTTP 200).

Tick `[x]` khi xong. Ghi chú kết quả ngay dưới mỗi mục để không phải nhớ/lục lại chat.

---

## Nhóm 1 — Cần BẠN chạy lệnh trên `labai217`

- [x] **A2 + A3 — Đóng băng `quickstart`, chụp lại transcript Appendix B** ✅ XONG (2026-09-28)
  - Gặp lỗi `yaml.representer.RepresenterError: numpy.float64` khi chạy `freeze_expected.py`
    → sửa `scripts/freeze_expected.py` thêm hàm `to_native()` ép toàn bộ payload về kiểu
    Python thường trước khi ghi YAML (commit `01510251` trên `software_x_tool`).
  - Gặp thêm lỗi `ModuleNotFoundError: No module named 'sr4rec'` sau khi xoá `sr4rec/` trùng
    lặp (package đang cài editable trỏ nhầm vào đó) → chạy lại `pip install -e ".[dev]"` từ
    gốc repo, fix xong.
  - `src/sr4rec/demos/expected/quickstart.yaml` đã đóng băng: bicubic 32.0, tiny_espcn 30.0,
    hr 29.0 (tolerance 0.2 mỗi cái).
  - `sr4rec reproduce quickstart` chạy PASS thật (28s, "Demo 'quickstart' reproduced within
    tolerance") → đã thay vào `paper/main.tex` Appendix B (Listing 3) + sửa câu văn Section 3
    Quickstart + đầu Appendix B không còn nói "not frozen in this development version" nữa.
  - Đã build lại PDF, kiểm tra trực quan trang Appendix B — hiển thị đúng, không tràn.

- [x] **A4 — Thông tin máy tham chiếu thật** ✅ XONG (2026-09-28)
  ```
  CPU: 13th Gen Intel(R) Core(TM) i7-13700F
  OS: Ubuntu 24.04.1 LTS
  PyTorch: 2.11.0+cu130 (CUDA 13.0)
  Python: 3.12.3
  GPU: NVIDIA GeForce RTX 3080 (đã có sẵn từ trước, khớp \DONEDevice trong macros.tex)
  ```
  Đã điền vào bảng ở `docs/reference_environment.md` (file này README có link tới, public), xoá
  luôn đoạn ghi chú thô dán tạm ở cuối file. **CẦN SYNC**: file này không nằm trong `paper/`, nó
  thuộc phần code/docs public → phải copy nội dung này (hoặc ít nhất bảng thông số) sang README của
  repo `sr4rec` nếu `sr4rec` cũng có link/nhắc tới reference environment — kiểm tra khi làm bước
  sync cuối cùng.

- [x] **B5 — `requirements.lock`** ✅ XONG (2026-09-28)
  Lần đầu bạn chạy `pip freeze` trực tiếp trên môi trường lab dùng chung của `labai217` → dính rác
  nặng: path riêng (`/root/ThaiLe/improve_lrsrn/...`, `/root/ThaiLe/new_exprerient/sraudit`), SSH
  URL riêng tới `software_x_tool`, và hàng chục package của project khác (`wandb`, `bitsandbytes`,
  `transformers`, `gfpgan`, `realesrgan`, `lpips`, `pyiqa`, `facexlib`...) — không được dùng bản
  đó. Đã hướng dẫn tạo venv sạch (`python3 -m venv /tmp/sr4rec_lockenv`, chỉ
  `pip install -e ".[dev]"` rồi mới freeze) → kết quả sạch, chỉ còn dependency thật của SR4Rec.
  - Ghi vào `requirements.lock` (gốc repo `software_x_tool`).
  - Phát hiện `torch==2.14.0` trong lockfile khác với `2.11.0+cu130` ghi ở A4 (máy tham chiếu) —
    không phải lỗi, do `pyproject.toml` chỉ ràng buộc `>=2.3`. Đã thêm 1 đoạn giải thích vào cuối
    `docs/reference_environment.md` (không đụng `paper/main.tex`) nói rõ lockfile không cần khớp
    tuyệt đối bảng tham chiếu, vì cơ chế tolerance của SR4Rec vốn thiết kế để hấp thụ kiểu lệch này.
  - **CẦN SYNC**: `requirements.lock` + đoạn giải thích trong `docs/reference_environment.md` phải
    port sang repo `sr4rec` ở bước sync cuối cùng.

---

## Nhóm 2 — Cần BẠN quyết định / cung cấp thông tin (không cần chạy lệnh)

- [x] **A5 — Tên thầy Vinh** ✅ XONG một phần (2026-09-28)
  Tìm được bằng chứng thật: 1 bài khác trích BibTeX nhóm tác giả EmbedKD dạng
  `author = {Do Nhat, Linh and Lam Tran Tuan, Dzi and Truong Hoang, Vinh}` (định dạng `Họ, Tên`) →
  xác nhận quy ước riêng của nhóm: family-names="Truong Hoang" (ghép 2 từ), given-names="Vinh". Đã
  sửa `CITATION.cff` ở **cả 2 repo** (`software_x_tool`, `sr4rec`):
  ```yaml
  - given-names: Vinh
    family-names: Truong Hoang
  ```
  ORCID thầy Vinh: `https://orcid.org/0000-0002-3464-3894` — xác nhận thật qua ORCID public API
  (given-names "Vinh", family-name "Truong Hoang", employment "Ho Chi Minh City Open University",
  works liệt kê đúng bài "EmbedKD..."). Đã điền vào `CITATION.cff` ở **cả 2 repo**.
  ORCID Thai Le Quang: `https://orcid.org/0009-0006-6427-2162` — xác nhận khớp qua ORCID public API
  (given-names "Thai", family-name "Le Quang"). Đã điền vào `CITATION.cff` ở cả 2 repo. **A5 xong
  hoàn toàn, cả 2 tác giả đều có ORCID.**

- [x] **B6, B7 — Đối chiếu template OSP gốc** ✅ XONG (2026-09-28)
  Bằng chứng tốt hơn cả template mẫu: bạn gửi PDF bài **EmbedKD đã published thật** trên SoftwareX
  36 (2026) 103029 (cùng nhóm tác giả, chị Linh + thầy Vinh) — dùng luôn số liệu thật thay vì đoán
  qua template.
  - **B7**: xác nhận nhãn C2 nguyên văn có chữ "GitHub": *"Permanent GitHub link to
    code/repository used for this code version"*. SR4Rec trước đó thiếu chữ "GitHub" ở dòng 155
    `paper/main.tex` → **đã sửa**.
  - **B6**: bài EmbedKD đã published **không có** bảng "Current executable software version"
    (S1–S8) nào cả, chỉ có 1 bảng Code metadata (C1–C8). Vậy S1–S8 không bắt buộc → SR4Rec hiện
    tại (không có bảng đó) là đúng, không cần thêm gì.
  - Phát hiện phụ (không phải lỗi, không cần sửa): SR4Rec có thêm dòng C3 "Permanent link to
    Reproducible Capsule" (Zenodo DOI) mà EmbedKD không đưa vào bảng (EmbedKD chỉ nhắc Zenodo DOI
    trong văn xuôi ở mục Impact) — SR4Rec làm kỹ hơn, giữ nguyên.

---

## Nhóm 3 — Tôi tự viết, chỉ cần bạn duyệt (không cần chạy gì)

- [x] **B1** — ✅ XONG (2026-09-28). Sửa đoạn "Metrics and statistics" (§2.2, `sec:functionalities`)
  trong `paper/main.tex`: nêu rõ $\alpha = 0.05$, điều kiện kép (Holm $p < \alpha$ **và** CI bootstrap
  không chứa 0 — đối chiếu đúng logic thật trong `src/sr4rec/stats.py::verdict()`), câu về việc
  ngưỡng cứng có thể gán nhãn sai ở ranh giới, và câu giải thích D3 chỉ 1 seed nên verdict không
  được kiểm tra đồng thuận qua nhiều lần train độc lập.

- [x] **B2** — ✅ XONG (2026-09-28). Sửa hàm `tab_summary()` trong `scripts/make_paper_assets.py`
  (thêm hậu tố `" (1 seed)"` vào verdict khi `len(seeds) == 1`, cập nhật caption giải thích) + patch
  tay `paper/generated/tab_summary.tex` (không có `runs/` ở máy này để chạy lại pipeline đầy đủ, nội
  dung patch khớp chính xác logic hàm đã sửa) → ô D3 giờ hiện "significant gain (1 seed)".
  **Cần regenerate thật trên labai217** khi có dịp để xác nhận khớp 100%, dù patch tay đã đúng logic.

- [x] **B3** — ✅ XONG (2026-09-28). Viết lại đoạn "Does image fidelity predict recognition? (D2)":
  bỏ câu "Fidelity therefore does not tell whether an SR model helps recognition" (logic ngược —
  D2 tự nó lại cho thấy fidelity VÀ Rank-1 cùng thứ tự). Thay bằng dẫn chứng chéo qua D1: 2 model có
  fidelity cao nhất ở D2 (swinir\_classical, span — train cho bicubic) chính là 2 model làm giảm
  Rank-1 có ý nghĩa ở D1; 2 model fidelity thấp nhất (realesrgan, swinir\_realworld — train cho
  real-world) là 2 model làm tăng Rank-1 ở D1. Câu "therefore" mới giờ suy ra đúng logic từ dữ kiện
  vừa nêu.

- [x] **B4** — ✅ XONG (2026-09-28). Thêm 2 câu vào cuối đoạn "Reproduction" (Section 3): nêu rõ giá
  trị tolerance thật (0.01pp cho `--eval-only`; `max(0.2pp, 3×sd)` cho full retrain, khớp
  `docs/reference_environment.md`) và giải thích chúng đo việc phần mềm tái lập đúng số của chính nó
  — khác hẳn với hiệu ứng SR (paired statistics ở §2.2) là câu hỏi khoa học riêng.

- [x] **B8** — ✅ XONG (2026-09-28). Thêm đoạn mới vào Impact (giữa đoạn giải thích protocol và đoạn
  "library is also a base"): 3 câu hỏi nghiên cứu mở dạng bullet list (style giống Impact của
  EmbedKD đã published), rút thẳng từ phát hiện thật của bài (vì sao đảo verdict giữa 2 protocol; SR
  giúp/hại ở ngưỡng kích thước nào ngoài D1; dissociation fidelity–recognition có đúng ở modal khác
  không) + trỏ rõ \texttt{Table~\ref{tab:validation}} (đã build thử, hiện đúng là **Table C.1** trong
  PDF) làm bằng chứng correctness đứng sau các câu hỏi đó.

- [x] **B9** — ✅ XONG (2026-09-28). Abstract cũ 179 từ → rút còn **136 từ** (trong khoảng 120-140),
  giữ nguyên toàn bộ số liệu thật (Real-ESRGAN +1.4pp, SwinIR real-world +1.1pp), chỉ cắt phần liệt
  kê dài dòng các metric phụ. Tạo thêm `paper/abstract_plain.txt` — bản ASCII phẳng (không LaTeX, không
  ký hiệu \$) sẵn sàng dán vào Editorial Manager.

- [x] **B10** — ✅ XONG (2026-09-28). Xác nhận qua `references.bib`: entry `hoang2019earvn` chỉ có 1
  tác giả "Hoang, Vinh Truong" — trùng đúng đồng tác giả bài này. Thêm nửa câu vào lần đầu nhắc
  EarVN1.0 ở Section 3 ("D1 uses EarVN1.0~\cite{hoang2019earvn}, published by a co-author of this
  paper, ...").

- [x] **A5 (DOI)** — ✅ XONG (2026-09-28). Điền `doi: 10.5281/zenodo.23008428` vào `CITATION.cff`.
  **Lưu ý**: đã sửa ở **cả 2 repo** (`software_x_tool` và `sr4rec`) luôn trong lần này, hơi khác quy
  trình "sync sau cùng" thường lệ — vì đây là 1 dòng an toàn, giống hệt nhau ở cả 2 nơi, và phát hiện
  `sr4rec/CITATION.cff` thật ra đã mới hơn bản ở `software_x_tool` (version 0.1.1 + URL thật, trong
  khi bản ở `software_x_tool` vẫn ghi version cũ `0.1.0.dev0` và URL placeholder `OWNER/sr4rec`) —
  hai file này đã lệch nhau sẵn từ trước, cần đồng bộ toàn diện ở bước "Làm sau cùng", không chỉ
  riêng DOI.

Đã build lại PDF (22 trang, không lỗi thật, chỉ vài underfull-hbox có sẵn từ trước) và dọn build
artifacts.

---

## Đối chiếu lại với `gop_y_sr4rec_softwarex.md` (bạn gửi lại nguyên văn 2026-09-28)

Bạn hỏi vì sao file này nói còn comment tiếng Việt — xác nhận mục **A4** của nó khớp đúng
`docs/reference_environment.md`, đã tự tìm ra và sửa từ sớm hôm nay (trước khi đọc được file này).
Đối chiếu toàn bộ các mục còn lại với trạng thái thật hiện tại, tìm thêm 3 việc mới:

- [x] **Tiêu đề phần mềm không khớp tiêu đề bài báo** ✅ XONG (2026-09-28)
  `CITATION.cff`, `.zenodo.json` và khối BibTeX trong `README.md` đều dùng bản rút gọn
  *"SR4Rec: a toolkit for measuring..."*, thiếu "A reproducible" và "image" so với tiêu đề thật
  của bài (`\title{}` trong `main.tex`). Đây chính là nguyên nhân bản ghi Zenodo hiện tại bị lệch
  tiêu đề mà file góp ý chỉ ra. Đã sửa cả 3 chỗ khớp đúng tiêu đề bài báo (`codemeta.json` đã đúng
  sẵn, không cần sửa). Bản ghi Zenodo mới (v0.1.2, ở bước "Làm sau cùng") sẽ lấy đúng tiêu đề này.

- [x] **`SR4Rec: 0.1.0` còn sót trong bảng `docs/reference_environment.md`** ✅ XONG. Cập nhật
  thành `0.1.2` cho khớp version hiện tại.

- [x] **`ruff>=0.4` không có cận trên** ✅ XONG. File góp ý cảnh báo đây chính là lỗi làm CI của
  người review đỏ suốt 1 tháng (ruff mở rộng bộ rule mặc định giữa các bản 0.x). Đã pin
  `ruff>=0.4,<0.17` ở cả `pyproject.toml` (dev extra) và `.github/workflows/ci.yml` (job `lint`
  trước đó cài `ruff` không ghim gì cả, độc lập với `pyproject.toml`).

- [x] **B8 bổ sung: bài claim validate 3 backbone nhưng mọi bảng chỉ có ResNet-18** ✅ XONG.
  Thêm 1 câu vào Technical limitations (`paper/main.tex`) nói rõ MobileNetV3-Small và
  ConvNeXt-Tiny đã validate nhưng không chạy trong các thí nghiệm ở bài này, nên kết luận có giữ
  nguyên qua backbone khác hay không là chưa kiểm chứng ở đây.

- Xác nhận các mục A1 (PyPI), A2, A3, A5 (concept vs version DOI, tên, ORCID), A6, B1, B2, B3, B4,
  B6, B7, B9, B10 đều đã khớp hoặc đã xử lý theo hướng khác nhưng tương đương (A1: bỏ hẳn PyPI
  thay vì sửa workflow, giống EmbedKD thật; B6: xác nhận không cần bảng S1-S8 bằng bằng chứng
  EmbedKD đã published, càng đúng hơn sau khi bỏ PyPI). Đã build lại PDF, không lỗi, đã sync toàn
  bộ sang `sr4rec`, ruff + pytest sạch (133 passed, 1 skipped).

- [x] **Test lại README đóng đúng vai người dùng mới (chỉ đọc chữ, không dùng hiểu biết riêng)** ✅
  XONG (2026-09-28). Bạn chỉ ra lần test trước tôi lỡ thêm bước `train_tiny_espcn.py` từ kinh
  nghiệm cá nhân, không phải từ README thật. Làm lại đúng cách: tải `README.md` thật từ GitHub,
  clone sạch, chỉ gõ đúng lệnh trong khối code Section 3 (2 dòng), không thêm gì —
  **tái hiện đúng lỗi `exit code 3: Demo inputs are missing`** vì README lúc đó thật sự thiếu
  bước train weights ở khối "try it now". Đã sửa: thêm dòng
  `python examples/sr_models/train_tiny_espcn.py` vào khối lệnh Section 3, và viết lại câu ở
  Section 8 (trước ghi "needs no external SR weights" — dễ hiểu lầm là không cần bước nào cả).
  Verify lại: chạy đúng 3 dòng mới → không còn lỗi "missing", đi thẳng tới bước train + reproduce
  (dừng ở tolerance mismatch — thuộc việc treo GPU bên dưới, không phải lỗi tài liệu nữa).
  Đã sync sang `sr4rec`.

- [ ] **README chưa tự đủ để tải Oxford-IIIT Pet** (đang verify) — bạn hỏi "ghi vậy người dùng
  sao biết tải về rồi trong đó có cái nào" → đúng, tự vào trang
  `https://www.robots.ox.ac.uk/~vgg/data/pets/` kiểm tra thật (qua WebFetch): trang có 3 lựa chọn
  (torrent + 2 file HTTP `images.tar.gz`/`annotations.tar.gz`), README không nói cần đúng 2 file
  nào, không nói cấu trúc thư mục. Đã verify URL trực tiếp ổn định (theo redirect):
  `https://thor.robots.ox.ac.uk/pets/{images,annotations}.tar.gz` (HTTP 200 trực tiếp, không qua
  redirect). Đã thêm `curl`/`tar` cụ thể vào khối lệnh Section 3. **Verify xong**: tải lại thật
  (791MB, 7393 ảnh), chạy `make_examples.py --pets` ra đúng 300 ảnh. Đã sync vào `sr4rec`.

- [x] **Review cấu trúc README tổng thể** ✅ XONG (2026-09-28). Bạn hỏi thứ tự 10 mục có hợp lý
  không (đóng vai người hoàn toàn mới). Kết luận: thứ tự tổng thể ổn, đúng khuôn mẫu phổ biến
  (khớp cả cách EmbedKD thật sắp xếp). Tìm ra 1 điểm bất nhất thật: mục 3 (Quick start), nhánh
  "own dataset" nhắc "Preparing your dataset" 2 lần nhưng **cả 2 đều nằm trong comment của code
  block, không phải link bấm được**; còn "Adding SR models" **không được nhắc lần nào** dù dòng
  lệnh ngay trên đó bảo "list SR weights under `sr:`" — đúng nội dung mục 5. Đã thêm 1 dòng link
  bấm được, cân bằng cả 2 mục sau khối lệnh. Đã sync vào `sr4rec`.

- [x] **Thêm link 3 dataset D1-D3 vào README Section 8** ✅ XONG (2026-09-28). Bạn cho biết LFW
  không tải được từ trang gốc, phải qua Kaggle mirror
  (`kaggle.com/datasets/atulanandjha/lfwpeople`); CUB từ `data.caltech.edu/records/65de6-vp158`;
  EarVN1.0 từ `data.mendeley.com/datasets/yws3v3mwx3/4`. Đã verify thật cả 3 link (CUB + EarVN1.0
  tải trực tiếp, không cần tài khoản; Kaggle cần tài khoản/API token — đã ghi rõ khác biệt này
  trong README). Đã sync sang `sr4rec`, chưa commit (bạn tự commit).

- [x] **Đổi lịch sử git `sr4rec`: bỏ Co-Authored-By: Claude** ✅ XONG (2026-09-28). Bạn muốn chỉ
  còn 1 tác giả `quangthai121121` (Thai Le Quang) trong toàn bộ lịch sử commit. Dùng
  `git filter-branch --msg-filter` xoá dòng `Co-Authored-By: Claude` khỏi 2 commit có dòng đó
  (`ae4fa5a`, `78fd807`), giữ nguyên nội dung file (diff rỗng, xác nhận bằng
  `git diff refs/original/... main`), force-push (`--force-with-lease`) lên GitHub. Xác nhận qua
  GitHub API: toàn bộ 8 commit chỉ còn tác giả "Thai Le Quang". Có branch backup cục bộ
  `backup-original-before-rewrite` (chưa push) phòng khi cần bản gốc.

- [x] **Ghi hash thật của `spanx4_ch48.pth`, sửa code để verify bằng hash thay vì tên file**
  ✅ XONG (2026-09-28). Bạn cung cấp SHA-256 thật:
  `28fef8c6c845a0169afed9f9f566679990ef4c03fef9885298655fb5e4036402` (đã xác nhận đúng độ dài 64
  ký tự hex). Trước đó phát hiện code (`src/sr4rec/sr/validated.py`) chỉ nhận diện SPAN qua
  **tên file**, không so hash — điểm yếu thật về toàn vẹn dữ liệu. Đã sửa:
  - Chuyển SPAN từ `VALIDATED_BY_NAME` (theo tên) sang `VALIDATED_WEIGHTS` (theo SHA-256), dùng
    đúng hash bạn đưa — giờ verify bằng hash y hệt 3 model kia.
  - Xoá hẳn `VALIDATED_BY_NAME` và nhánh "chỉ theo tên" vì giờ không còn model nào cần nó
    (không giữ code chết).
  - Đơn giản hoá `lookup()`: bỏ tham số `filename` không còn dùng, sửa nơi gọi
    (`src/sr4rec/sr/pth_source.py`).
  - Cập nhật `docs/adding_sr_models.md`: cột SHA-256 của SPAN từ "hash to be recorded" → hash
    thật.
  - Verify: `ruff check` sạch, `pytest -m "not slow"` 134 passed (không mất test nào). Đã sync
    sang `sr4rec`, verify lại lần nữa y hệt (133 passed do khác biệt slow-test collection giữa 2
    repo, không phải lỗi).

- [x] **So sánh văn phong với EmbedKD + viết lại README/docs cho gọn** ✅ XONG (2026-09-29). Bạn
  hỏi so văn phong (không phải độ dài) với README + `docs/faq.md` thật của EmbedKD. Phát hiện: không
  phải SR4Rec dài dòng tổng thể, mà **mật độ chữ/câu cao hơn** — bullet nhồi nhiều mệnh đề bằng dấu
  `;`, câu hỏi+trả lời FAQ nhồi chung 1 dòng (EmbedKD tách câu hỏi in đậm xuống dòng riêng), nhiều
  bảng hơn hẳn (SR4Rec 5 bảng, EmbedKD 0 bảng). Phát hiện phụ: FAQ EmbedKD đã có sẵn đúng câu
  "differ on different GPU → xem determinism contract" — xác nhận mục Determinism vừa thêm là đúng
  hướng. Đã viết lại:
  - `docs/faq.md`: đổi hẳn format (câu hỏi in đậm dòng riêng, câu trả lời dòng dưới), thêm link
    tới mục Determinism.
  - `README.md`: viết lại bullet "What SR4Rec enforces" (bớt nhồi mệnh đề), câu "Tip for large
    studies" (tách 2 câu), đoạn văn Section 8 (tách 3 đoạn rõ ràng thay vì 1 đoạn lồng code block
    giữa câu), mục 9 Limitations/Roadmap/Contributing/Licences (tách 4 khối có tiêu đề in đậm riêng
    thay vì 1 đoạn văn dài).
  - `docs/preparing_dataset.md`: tách đoạn "Rounding" dày đặc công thức thành 2 đoạn.
  - **Cố ý không đụng**: `docs/methods.md` (spec khoa học, cắt gọn có nguy cơ mất chi tiết reviewer
    cần), `docs/config_reference.md` (tự sinh từ code, CI kiểm tra khớp, không được sửa tay),
    `docs/adding_sr_models.md`/`docs/report_guide.md`/`docs/output_files.md` (đã đủ gọn, đánh giá
    không cần sửa).
  - Verify: không anchor nào gãy, không đụng code (`ruff`/`pytest` không cần chạy lại vì chỉ sửa
    markdown). Đã sync sang `sr4rec`.

- [x] **BUG THẬT tìm ra trên GPU: SR inference không tất định, gây `MISMATCH` ngay cả cùng loại
  phần cứng** ✅ ĐÃ SỬA (2026-09-29), **cần bạn chạy lại để xác nhận**. Bạn chạy
  `sr4rec reproduce d3_cub --eval-only` thật trên `labai217` (đúng máy đã đóng băng số liệu D3,
  CUDA thật, không phải trường hợp MPS vs CUDA như trước) — vẫn lệch tolerance (0.01pp, rất chặt):
  ```
  backbone   method             expected   got     tolerance  result
  resnet18   bicubic            60.49      60.49   0.01       OK
  resnet18   realesrgan         58.03      57.96   0.01       MISMATCH (lệch 0.07pp)
  resnet18   swinir_classical   61.62      61.62   0.01       OK
  resnet18   swinir_realworld   57.39      57.35   0.01       MISMATCH (lệch 0.04pp)
  resnet18   span               61.74      61.70   0.01       MISMATCH (lệch 0.04pp)
  resnet18   hr                 63.36      63.36   0.01       OK
  ```
  **Tìm ra nguyên nhân gốc thật (đọc code, không đoán)**: `set_determinism()` (bật
  `torch.backends.cudnn.deterministic=True`, tắt `cudnn.benchmark`,
  `use_deterministic_algorithms(True)`) **chỉ được gọi bên trong vòng lặp train recognizer**
  (`rec/engine.py:77`). Nhưng `pipeline.py` gọi `make_sr_images()` (chạy suy luận SwinIR/Real-ESRGAN/
  SPAN qua ảnh) **trước** `evaluate()` (nơi mới gọi tới train recognizer) — nghĩa là lúc SR model
  chạy suy luận, cờ tất định **chưa hề được bật**, cuDNN dùng thuật toán conv mặc định (không tất
  định giữa các lần chạy, dù cùng máy) → ảnh SR sinh ra lệch pixel nhỏ → lan sang kết quả eval của
  checkpoint đã đóng băng. Giải thích đúng khớp dữ liệu quan sát: `bicubic`/`hr` (không qua mạng
  neural) khớp tuyệt đối; `realesrgan`/`swinir_realworld`/`span` (đều là mạng neural) lệch nhẹ.
  **Đã sửa**: gọi `set_determinism(0)` ngay đầu `Run.execute()` (`pipeline.py`), trước
  `make_lr_images()`/`make_sr_images()`, để tất định bao trùm toàn bộ pipeline chứ không chỉ lúc
  train. Verify: `ruff`/`pytest` sạch (134 passed), verify cờ `deterministic_algorithms: true` đã
  có ngay từ đầu `fingerprint.yaml` (test lại trên Mac — vẫn lệch vì đó là vấn đề khác: MPS vs
  CUDA, không phải bug vừa sửa). Đã sync sang `sr4rec`, verify lại lần nữa y hệt.
  **Cập nhật — điều tra tiếp vì fix không làm hết MISMATCH ngay**: bạn chạy lại thật trên
  `labai217` sau khi pull code mới, vẫn `MISMATCH` ở đúng 3 dòng cũ. Loại trừ lần lượt 4 khả năng
  bằng dữ liệu thật (không đoán):
  1. Thiếu cờ tất định? → Không, `fingerprint.yaml` xác nhận `deterministic_algorithms: true`.
  2. Lệch version PyTorch (2.14.0 vs 2.11.0 gốc)? → Không, test lại đúng venv gốc `2.11.0+cu130`
     vẫn ra cùng con số lệch.
  3. File weight sai/khác bản gốc? → Không, SHA-256 trong report khớp 100% với bảng chuẩn
     `docs/adding_sr_models.md` (`4fa0d38…`, `129dc77…`, `b9afb61…`, `28fef8c…`).
  4. Phép tính nào đó âm thầm rơi về chế độ không tất định (`warn_only=True` không báo lỗi)?
     → Không, `PYTHONWARNINGS=always` chạy lại không in ra cảnh báo "deterministic" nào.
  **Kết luận đúng**: fix `set_determinism()` **có tác dụng thật** — nhưng số liệu `expected` cũ
  được đóng băng **trước khi có fix** (lúc đó SR inference chạy không tất định, ra 1 con số
  "may rủi" của đúng lần chạy đó). Sau fix, mọi lần chạy lại đều tự nhất quán ra 1 con số khác
  nhưng **ổn định** — không còn là lỗi, mà là "con số cũ đã lỗi thời, cần đóng băng lại".
  **Đã xử lý**: chạy `python scripts/freeze_expected.py runs/reproduce_d3_cub_eval_only_3 d3_cub`
  trên `labai217`, lấy đúng giá trị mới, áp vào `src/sr4rec/demos/expected/d3_cub.yaml` (source
  thật `software_x_tool`), đã verify: **con số headline của bài báo không đổi** (span vs bicubic
  vẫn ra đúng +1.2pp, "significant gain", khớp Table 5 — không cần sửa bài báo). Test + ruff sạch,
  đã sync sang `sr4rec`.
  **Xác nhận cuối (2026-09-29)**: chạy lại `d3_cub --eval-only` trên `labai217` → cả 6 dòng `OK`,
  "reproduced within tolerance". Kiểm tra chéo thêm 2 demo còn lại bằng `--eval-only` thật trên
  cùng máy: **D1 (`d1_earvn`) 5/5 OK**, **D2 (`d2_lfw`) 6/6 OK** — cả 2 đúng ngay từ đầu, không cần
  đóng băng lại (bug có tính xác suất: phụ thuộc kích thước ảnh cụ thể của từng dataset ảnh hưởng
  cuDNN chọn thuật toán, D3 rơi vào trường hợp không tất định, D1/D2 thì không). Toàn bộ số liệu
  headline bài báo (Table 3, 4, 5) đã được xác nhận tái lập đúng bằng `--eval-only` trên máy tham
  chiếu thật — đây là mức bằng chứng tái lập mạnh nhất có thể có trước khi nộp bài.
  **Mảnh ghép cuối**: chạy lại `sr4rec reproduce quickstart` (train lại từ đầu, không phải
  eval-only) trên `labai217` (CUDA) → khớp tuyệt đối 3/3 (32.00/30.00/29.00, đúng từng chữ số) —
  xác nhận đúng giả thuyết ban đầu: lệch trên Mac (Apple GPU/MPS) trước đó là do khác loại phần
  cứng (MPS vs CUDA), không phải cùng loại bug với D3. **Toàn bộ việc tái lập — quickstart, D1,
  D2, D3, cả 2 mức eval-only và train lại — đã verify OK trên máy tham chiếu thật. Không còn việc
  treo nào.**

## VIỆC TREO — cần bạn xác nhận trên GPU thật

- [ ] **`sr4rec reproduce quickstart` lệch tolerance khi chạy trên máy khác `labai217`**
  Đóng vai người dùng mới, clone thật từ GitHub, tải thật Oxford-IIIT Pet, chạy đúng luồng README
  trên máy Mac này (Apple GPU M5 Pro, MPS backend, Python 3.14.7) — không crash, nhưng **kết quả
  sai lệch tolerance** (exit code 2), lặp lại y hệt ở 2 lần chạy (không phải random):
  ```
  backbone   method       expected   got     tolerance  result
  resnet18   bicubic      32.00      32.00   0.20       OK
  resnet18   tiny_espcn   30.00      29.00   0.20       MISMATCH
  resnet18   hr           29.00      30.00   0.20       MISMATCH
  ```
  `fingerprint.yaml` xác nhận máy Mac chạy `device: mps` (Apple GPU), không phải CPU dù
  README/paper đều nói "examples run on a CPU" — có thể đây là nguyên nhân (số liệu gốc đóng băng
  trên CUDA của labai217, số liệu tái lập trên MPS của Mac, khác backend/phần cứng → lệch 1pp,
  tương đương lệch đúng 1 ảnh test trong 100 ảnh). Cũng phát hiện thêm: Python 3.14.7 trên máy Mac
  vượt ngoài dải hỗ trợ công bố (3.10-3.12), `pyproject.toml` không có cận trên nên `pip install`
  vẫn cài được, không cảnh báo gì.
  Bạn nói để kiểm tra lại việc này trên GPU (CUDA) trước khi kết luận — **chưa xử lý, đang chờ**.
  Nếu xác nhận đúng là do khác backend/phần cứng: cần quyết định nới tolerance của `quickstart` hay
  ghi rõ giới hạn "chỉ tái lập chắc chắn trên cùng loại phần cứng" trong README/paper (giống cách
  EmbedKD viết: "Same machine + same seed is bit-exact; across GPUs, expect differences within the
  tolerances"). README hiện cũng nên sửa "examples run on a CPU" cho đúng thực tế (`device: auto`
  ưu tiên GPU/MPS nếu có, không ép CPU).

## Làm sau cùng (sau khi Nhóm 1–3 xong hết)

- [ ] Cắt tag `v0.1.2`, tạo Zenodo record mới, cập nhật C1/C2/C3 trong `paper/main.tex`
- [ ] Kiểm lại toàn bộ link công khai (GitHub, GitHub tree, Zenodo DOI) ở chế độ chưa đăng nhập, ngay trước khi bấm nộp
- [x] **Đồng bộ toàn diện `software_x_tool` ↔ `sr4rec`** ✅ XONG (2026-09-28)
  Phát hiện 2 repo lệch nhau **2 chiều** (không chỉ 1 chiều như tưởng):
  - `sr4rec` có sẵn nhiều fix mà `software_x_tool` chưa có (làm ở phiên trước, chưa port ngược):
    AI-smell cleanup (`check_english.py`, mã B-code trong docstring 9 file test, `ci.yml`,
    `.pre-commit-config.yaml`, PR template), fix Windows CI (`encoding="utf-8"` ở `fingerprint.py`,
    `split.py`, `test_cli.py`, `test_end_to_end.py`), bỏ PyPI, URL thật thay vì `OWNER/sr4rec`,
    `scripts/checkpoints_manifest.json` đầy đủ 42 checkpoint thật. → Đã copy ngược toàn bộ vào
    source thật của `software_x_tool`.
  - `software_x_tool` có các fix mới của phiên này mà `sr4rec` chưa có: `docs/reference_environment.md`
    (A4), `scripts/freeze_expected.py` (fix numpy), `scripts/make_paper_assets.py` (fix B2),
    `requirements.lock` (file mới), `quickstart.yaml` (đóng băng — **phát hiện quan trọng: giá trị
    thật từ labai217 chưa hề được commit ở đâu cả**, đã ghi thẳng vào source vì đã biết chắc giá trị
    thật từ output bạn dán trước đó).
  - Phát hiện thêm: `scripts/make_paper_assets.py`, `make_qualitative_figure.py`,
    `check_sr_fidelity.py` là tooling riêng cho bài báo (tự ghi rõ "(paper, ...)" trong docstring),
    bị `make_release.sh` cuốn vào release do copy nguyên `scripts/` không lọc — theo quyết định của
    bạn, đã sửa `make_release.sh` loại 3 file này khỏi bản release từ nay, và sửa 1 câu trong
    README.md không còn trỏ tới đường dẫn không tồn tại trong bản public.
  - Version: bump `software_x_tool` lên `0.1.2.dev0` (pyproject.toml/codemeta.json),
    `CITATION.cff`/`.zenodo.json`/`codemeta.json` đồng bộ tên "Truong Hoang, Vinh" + ORCID cả 2 tác
    giả ở **cả 2 repo**. Thêm mục `[0.1.2]` vào `CHANGELOG.md`.
  - Quy trình dùng đúng pipeline đã thiết kế sẵn: sửa source `software_x_tool` → `bash
    scripts/make_release.sh` → diff `release/` vs `sr4rec` (review từng file) → `rsync -a --delete`
    (loại trừ `.git`, cache) copy `release/` đè vào `sr4rec`. Đã kiểm tra không còn tham chiếu treo
    (`git grep`), Python syntax OK. **Chưa commit/push gì trong `sr4rec`** — dừng ở bước copy file,
    chờ xác nhận trước khi commit.

- [x] **Quét sạch mọi mention "paper" khỏi `sr4rec`** ✅ XONG (2026-09-28)
  Theo yêu cầu "chỉ release software thôi": grep toàn bộ `sr4rec` cho từ "paper", tìm thêm 7 chỗ
  ngoài 3 script đã loại ở bước trên:
  - `README.md`: đổi hẳn mục "## 11. Reproducing the paper" → "## 11. Reproducing the demos", bỏ
    cột "Role in the paper" trong bảng demo (đổi thành "What it demonstrates"), xoá câu nhắc
    "tables and figures of the SoftwareX paper...", **và fix luôn 1 chỗ nội dung đã sai từ trước**:
    đoạn cảnh báo cũ nói `sr4rec reproduce quickstart` luôn exit code 3 vì "no frozen expected
    results" + trỏ "Appendix B of the paper" — không còn đúng nữa từ khi đóng băng quickstart, đã
    viết lại đúng hành vi thật.
  - `CONTRIBUTING.md`: "one paper dataset" → "one of the shipped demo datasets".
  - `DATA_AND_MODEL_LICENSES.md`: bỏ vế "...or in the paper figures".
  - `docs/reference_environment.md`: "the paper demos" → "the shipped demos".
  - `scripts/freeze_expected.py`, `src/sr4rec/demos/expected/quickstart.yaml`: tổng quát hoá
    docstring/comment, không còn neo vào "paper".
  - `tests/fixtures/synthetic.py`: bỏ chữ "paper" khỏi docstring.
  - Giữ nguyên đúng 1 chỗ: `CONTRIBUTING.md` dòng "within 0.05 dB of the paper" — đây là nhắc tới
    **bài báo gốc của từng SR model** (căn cứ đối chiếu PSNR/SSIM khi thêm model mới), không liên
    quan bài SoftwareX của SR4Rec, nên hợp lệ.
  - Grep cuối cùng trên toàn bộ `sr4rec` sau khi sync: chỉ còn đúng dòng hợp lệ đó, không còn tham
    chiếu treo tới 3 script đã xoá, Python syntax OK.

- [x] **Rút gọn README theo kiểu EmbedKD** ✅ XONG (2026-09-28)
  Bạn nhận xét README SR4Rec (431 dòng) dài hơn hẳn EmbedKD thật (đã tải `v0.1.5`, chỉ **85 dòng**).
  Xác nhận đúng: README cũ lặp lại gần hết nội dung 5 file đã có sẵn trong `docs/`
  (`preparing_dataset.md`, `adding_sr_models.md`, `config_reference.md`, `report_guide.md`,
  `methods.md`) ngay trong README rồi mới link ở cuối mỗi mục.
  - Viết lại README: 431 → **272 dòng** (giảm ~37%), 14 mục → 10 mục, cắt phần trùng lặp (snippet
    convert dataset, bảng validated-SR-models, ví dụ dry-run...) chỉ giữ bảng tóm tắt + link `docs/`.
  - Tạo 2 file `docs/` mới (theo đúng cách EmbedKD tách `docs/faq.md`): `docs/faq.md` (chuyển
    nguyên mục FAQ), `docs/output_files.md` (chuyển nguyên mục Output files).
  - **Tiện phát hiện + sửa 1 lỗi thật**: khối BibTeX cuối README vẫn placeholder cũ —
    `author = {..., Hoang, V. T.}`, `version = {0.1.0}`, `doi = {10.5281/zenodo.XXXXXXX}` — đã sửa
    đúng theo các fix DOI/tên/version đã làm ở các mục trước.
  - Kiểm tra: toàn bộ anchor TOC còn khớp (script kiểm tra tự động, không anchor nào gãy), không
    file nào khác trỏ tới anchor cũ. Đã sync vào `sr4rec`.

- [x] **Điều tra + fix CI fail thật trên `main` (ubuntu-3.11, macos-3.11)** ✅ XONG (2026-09-28)
  Bạn dán log lỗi `ResolutionImpossible` khi cài `matplotlib`/`python-dateutil`. Kiểm tra bằng
  `gh run list` phát hiện đây **đúng là commit mới nhất trên `main` đang đỏ thật**
  (`36409778366`, "Drop PyPI distribution...") — trước đó tôi báo nhầm CI đã xanh hết.
  - Đọc log đầy đủ qua `gh run view --log` (log bạn dán bị cắt mất dòng quan trọng): nguyên nhân
    thật là `ReadTimeoutError` khi `pip` tải `python-dateutil` từ PyPI (mạng chập chờn trên
    runner GitHub Actions), không phải lỗi cấu hình hay lỗi code. Pip retry 5 lần đều timeout rồi
    coi gói đó "không có bản nào khả dụng", backtrack qua hàng chục version `matplotlib` vô ích,
    cuối cùng báo `ResolutionImpossible`.
  - **Cập nhật**: sau đó phát hiện thêm 1 lỗi Windows CI thật khác (test mới viết
    `test_reproduce_missing_local_inputs` hardcode dấu `/` trong khi Windows dùng `\`) — đã sửa
    (commit `ae4fa5a`, push trực tiếp lên `main`), CI chạy lại **xanh hết 9 tổ hợp + lint +
    examples** (run `36426702337`).
  - Chạy `gh run rerun --failed` để kiểm chứng — theo dõi qua `gh run watch`: **toàn bộ 9 tổ hợp
    (kể cả ubuntu-3.11, macos-3.11) pass hết khi chạy lại, không sửa gì** → xác nhận chắc chắn là
    lỗi mạng thoáng qua.
  - Bạn hỏi so sánh với CI thật của EmbedKD (`v0.1.5`): phát hiện CI EmbedKD đơn giản hơn không
    phải vì xử lý mạng tốt hơn, mà vì **test ít tổ hợp hơn hẳn** (chỉ ubuntu-latest, chỉ Python
    3.10+3.12, né hẳn Windows/macOS/3.11 — đúng nơi từng bắt được 2 bug Windows thật ở SR4Rec).
  - Quyết định cuối: **giữ nguyên đủ 3 OS × 3 Python**, chỉ thêm `cache: pip` vào
    `actions/setup-python` (giảm số lần gọi mạng PyPI, đúng phần EmbedKD thực sự khác — cache pip
    — chứ không phải do test ít hơn). Đã sync `ci.yml` sang `sr4rec`.

- [x] **Sửa 2 lỗi thật khiến người dùng mới chạy README bị vướng** XONG (2026-09-28)
  Bạn hỏi README đã dễ hiểu/dễ làm theo chưa - đọc lại từng bước như người dùng mới thật sự gõ
  lệnh, phát hiện 2 vấn đề thật (không phải hình thức):
  - Mục 3 "Quick start": lệnh `cd my_project` chạy trước khi có `mkdir my_project` - copy-paste
    nguyên xi sẽ báo lỗi "No such file or directory". Đã thêm
    `mkdir -p my_project/data/my_dataset && cd my_project`.
  - Con đường "thử ngay không cần chuẩn bị gì" (`sr4rec reproduce quickstart`, tương đương
    `embedkd fit --config configs/quickstart_cpu.yaml` của EmbedKD) bị giấu ở mục 8, không nhắc ở
    mục 3. Kiểm tra thật bằng `git ls-files`: xác nhận `examples/data/pets_mini/images/` bị
    gitignore, không có sẵn trong repo - nghĩa là quickstart vẫn cần tự tải Oxford-IIIT Pet rồi
    chạy `make_examples.py --pets` trước, không "zero-setup" hoàn toàn như EmbedKD (dùng dữ liệu
    tổng hợp trong bộ nhớ, không cần tải gì). Phát hiện thêm câu văn cũ ở mục 8 nói quickstart
    "has no such requirement" là sai thông tin - đã sửa lại đúng thực tế, thêm link trỏ 2 chiều
    giữa mục 3 và mục 8.
  - Đã kiểm tra: `--pets` là flag thật trong `scripts/make_examples.py` (grep xác nhận), anchor
    TOC không gãy. Đã sync sang `sr4rec`.

- [x] **Review toàn diện `sr4rec` trước khi commit** ✅ XONG (2026-09-28)
  Quét lại từ đầu, không tin vào các lần review trước, kiểm tra bằng lệnh thật:
  - Grep sạch: không còn "paper"/"SoftwareX"/"Appendix" (trừ 1 dòng hợp lệ), không B-code,
    không `check_english`, không rò rỉ hạ tầng nội bộ (`labai217`, `software_x_tool`,
    `/root/ThaiLe`), không TODO/FIXME thật, không mention Claude/AI/LLM.
  - Không còn placeholder (`OWNER`, `zenodo.XXXXXXX`, ORCID giả `0000-0000-0000-0000`).
  - Không file rác được track (`.DS_Store`, `__pycache__`, `.egg-info`), không file nhị phân lớn
    bất thường (file lớn nhất 32K), 122 file tracked — hợp lý cho 1 toolkit nhỏ.
  - `py_compile` toàn bộ `.py` trong working tree: OK. `pyproject.toml` parse bằng `tomllib`: OK.
  - **Chạy thật `ruff check .` + `pytest -m "not slow"`** (cài editable vào venv có sẵn
    `/tmp/sr4rec_release_test_venv`, dùng `--no-deps` khỏi tải lại torch) — **phát hiện 1 test
    fail thật**: `test_reproduce_unknown_and_unfrozen` giả định `quickstart` chưa đóng băng (viết
    từ trước khi làm A2+A3), giờ `quickstart` đã frozen nên code đi nhánh khác
    (`src/sr4rec/reproduce.py:129`: chỉ ghi `<demo>_config.yaml` khi **chưa** frozen) → assertion
    cũ sai. Đã tách lại thành 2 test đúng hành vi thật: `test_reproduce_unknown_demo` (demo không
    tồn tại) và `test_reproduce_missing_local_inputs` (demo đã frozen nhưng thiếu dữ liệu local,
    đúng behavior thật của `quickstart` bây giờ). Sửa ở `software_x_tool` (nguồn) trước, verify
    134 test pass + ruff sạch, rồi mới sync sang `sr4rec` và verify lại lần nữa y hệt.
  - `docs/` không có file mồ côi (đối chiếu tất cả đều được README/CONTRIBUTING link tới).
  - **Kết luận: `sr4rec` đã sẵn sàng để commit.**

- [x] **Cập nhật `paper/main.tex` cho khớp bằng chứng tái lập GPU thật vừa xác nhận** ✅ XONG (2026-09-29)
  Sau chuỗi điều tra + fix bug tất định trong `pipeline.py` (D3/CUB) và verify lại toàn bộ 4 demo
  (`quickstart`, D1, D2, D3) trên GPU tham chiếu thật (`labai217`, RTX 3080), đoạn
  `\paragraph{Reproduction}` (Section 2.2, dòng ~492-503) được sửa để khớp đúng bằng chứng thật,
  tránh overclaim:
  - Thêm "D2 and D3 match the same way" — giờ có bằng chứng thật cho cả 3 demo eval-only, không
    chỉ D1 như trước.
  - Câu cũ nói tolerance "bound... across hardware and software versions" là **overclaim** — thực
    nghiệm (test trên Mac/Apple GPU) cho thấy tolerance không bao trùm khác biệt giữa các loại
    GPU/backend khác nhau. Sửa lại theo giọng văn EmbedKD ("expect ..." thay vì hứa hẹn số cụ
    thể): "These reproduction tolerances (...) hold on the same type of hardware, as demonstrated
    for all three demonstrations above. Across GPU vendors or backends, expect larger deviations;
    this is documented as an expected limit, not a defect, in the reference environment notes."
    — câu sau trỏ đúng tới mục "Determinism" mới thêm ở `docs/reference_environment.md`.
  - Đã kiểm tra `\paragraph{Robust execution}` (dòng 340) và Appendix B "Console session" (dòng
    618): cả hai chỉ mô tả hành vi runtime/transcript trên đúng máy tham chiếu (RTX 3080), không
    đưa ra tuyên bố tái lập xuyên phần cứng nào — không cần sửa. Grep toàn bài
    `across hardware|any hardware|regardless of hardware|any GPU|all hardware|any machine` không
    còn khớp nào khác.
  - Build lại PDF (`latexmk -pdf -gg` rồi `latexmk -pdf`): 22 trang, không lỗi mới (chỉ các cảnh
    báo underfull-hbox có sẵn từ trước). Verify bằng `pdftotext` đúng câu chữ đã lên PDF.
  - Không cần sync sang `sr4rec` — `paper/` không nằm trong danh sách copy của
    `scripts/make_release.sh`. Không đổi code, không cần chạy lại `pytest`/`ruff`.

- [x] **Khối email tác giả (frontmatter): thử bớt còn 1 email rồi khôi phục cả 2 theo style EmbedKD**
  ✅ XONG (2026-09-29)
  Thử đầu tiên: xoá `\ead{thailq@hub.edu.vn}` của Thai, chỉ giữ email của Vinh (corresponding
  author) — verify bằng `pdftotext` ra đúng 1 dòng "Email address: vinh.th@ou.edu.vn (Vinh Truong
  Hoang)". Sau đó người dùng yêu cầu đổi lại cho giống định dạng bài EmbedKD: khôi phục
  `\ead{thailq@hub.edu.vn}` cho Thai, giữ nguyên `\ead{vinh.th@ou.edu.vn}` + `\cortext[cor1]` cho
  Vinh — `elsarticle` tự in gộp thành "Email addresses: thailq@hub.edu.vn (Thai Le Quang),
  vinh.th@ou.edu.vn (Vinh Truong Hoang)" khi có ≥2 tác giả có `\ead`, đã verify đúng câu này bằng
  `pdftotext`. **Trạng thái cuối cùng: cả 2 email đều hiển thị**, chỉ Vinh mang dấu `*`
  Corresponding author. Không đổi C9 "Support email for questions" (vẫn `thailq@hub.edu.vn`). Build
  lại PDF cả 2 lần, 22 trang không đổi, không lỗi LaTeX mới. Không sync `sr4rec` (paper/ ngoài
  phạm vi release), không cần chạy lại `pytest`/`ruff`.

- [x] **Đánh tag `v0.1.2` cho `sr4rec`, tạo Zenodo record mới, cập nhật bài báo cho khớp**
  ✅ XONG (2026-09-29)
  Bạn tự tay đánh tag/publish release theo hướng dẫn từng bước tôi đưa (bump version 2 file
  `pyproject.toml` + `codemeta.json` ở cả `software_x_tool` và `sr4rec` từ `0.1.2.dev0` →
  `0.1.2`, commit + push, đợi CI xanh, `git tag v0.1.2` + push, publish GitHub Release, tự sửa
  release note qua web cho ngắn gọn). Zenodo tự động archive, DOI mới:
  `10.5281/zenodo.23041108`.
  - Đối chiếu với bài EmbedKD thật (`1-s2.0-S2352711026005200-main.pdf`, bạn gửi) để lấy đúng quy
    ước: EmbedKD **không** có hàng "Permanent link to Reproducible Capsule" trong bảng Code
    metadata (chỉ 8 hàng C1-C8, "Legal Code License" là C3); DOI chỉ nhắc trong văn xuôi ở mục
    Impact ("The released version is archived on Zenodo..."), không lặp trong bảng metadata.
  - Theo yêu cầu, sửa bảng "Code metadata" của SR4Rec (dòng ~143-168) cho khớp: **bỏ hẳn** hàng
    "Permanent link to Reproducible Capsule" (C3 cũ), dồn các hàng còn lại lên 1 bậc — giờ cũng
    đúng 8 hàng (C1-C8), "Legal Code License" là C3 giống EmbedKD. Không đụng cấu trúc Data
    availability (SR4Rec vẫn giữ DOI ở đó, khác EmbedKD để DOI ở Impact — chỉ sửa đúng phần bảng
    metadata theo yêu cầu, không mở rộng sang đổi luôn vị trí DOI).
  - Cập nhật C1 (`v0.1.1` → `v0.1.2`), C2 (link `tree/v0.1.1` → `tree/v0.1.2`), và Data
    availability (DOI cũ `zenodo.23011230` → DOI mới `zenodo.23041108`) cùng lúc sau khi có DOI
    thật. Verify bằng `pdftotext`: cả 3 chỗ đúng giá trị mới, không còn `v0.1.1`/DOI cũ nào sót.
  - Build lại PDF nhiều lần trong quá trình sửa, 22 trang không đổi, không lỗi LaTeX mới.
  - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). Không cần chạy lại `pytest`/`ruff`
    (chỉ đổi văn bản LaTeX + version string, không đổi logic code).

- [x] **Table 5 (summary): xoay trục để bớt cột; sửa bảng/hình trôi sang section khác**
  ✅ XONG (2026-09-29)
  - **Xoay trục Table 5**: bảng gốc 11 cột (Demo, Dataset, Mode, Protocol, Seeds, Classes, Test,
    Best SR, $\Delta$, Verdict, Hours) trên 4 dòng, phải dùng `table*` (tràn 2 cột) + `adjustbox`
    ép nhỏ font mà vẫn chật. Theo yêu cầu người dùng, xoay trục: 4 demo thành 4 cột, 10 thuộc tính
    thành 10 dòng — chỉ còn 5 cột, vừa 1 cột trang, font thường, không cần ép nhỏ. Sửa hàm
    `tab_summary()` trong `scripts/make_paper_assets.py` (nguồn sinh bảng) và hand-patch
    `paper/generated/tab_summary.tex` theo đúng logic hàm mới (máy này không có `runs/` để chạy
    lại script thật). Verify bằng ảnh render trang PDF thật.
  - **Bảng/hình trôi sang section khác**: người dùng nhớ từng thấy hiện tượng này, rà lại bằng
    cách map caption Table/Figure với heading Section theo từng trang PDF (`pdftotext -layout` +
    render ảnh từng trang nghi vấn). Phát hiện 2 chỗ thật: (1) Figure 1 (kiến trúc, thuộc §2.1)
    trôi sang trang 5, nằm sau đoạn text của §2.2; (2) nghiêm trọng hơn, Figure 4 + Table 5 + Table
    6 (đều thuộc Section 3) trôi qua trang 12-13, tức là **sau khi** heading "4. Impact" đã xuất
    hiện ở trang 11 — người đọc thấy 3 hình/bảng của Section 3 nằm giữa phần mở đầu và phần còn
    lại của Impact. Nguyên nhân: các float này dùng `[t]`/`[!htbp]` (gợi ý trôi), không đủ chỗ nên
    LaTeX đẩy sang trang sau, kể cả khi đã qua ranh giới section.
  - Sửa bằng cách đổi sang `[H]` (package `float`, đã có sẵn, cùng kiểu Table 1 "Code metadata" và
    `tab_validation` đã dùng từ trước) — ép in đúng vị trí nguồn, không trôi qua section khác. Sửa
    ở `main.tex` (Figure 1, Figure 4) và `scripts/make_paper_assets.py` (`tab_summary`,
    `tab_latency`, thêm `pos="H"`) + hand-patch 2 file generated tương ứng.
  - Build lại PDF, quét lại **toàn bộ** heading + caption theo từng trang (script Python đối chiếu
    `pdftotext -layout`), xác nhận không còn bảng/hình nào lẫn sang section khác ở bất kỳ đâu
    trong bài (kể cả ranh giới Appendix A/B/C). Verify trực quan bằng ảnh render các trang trước
    và sau khi sửa (Figure 1 → trang 5 đúng trước 2.2; Table 6 → trang 13 đúng trước "4. Impact").
    22 trang không đổi.
  - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). Không cần chạy lại `pytest` (không
    đổi code core); `ruff` đã chạy trên `scripts/make_paper_assets.py` sau khi sửa, sạch.

- [x] **Table 3 (D1) và Table 4 (D2) chữ nhỏ: xoay trục giống Table 5, đo đạc thật để chọn độ**
  **rộng cột thay vì đoán** ✅ XONG (2026-09-29)
  Table 3 (9 cột × 5 dòng) và Table 4 (7 cột × 6 dòng) đều bị `adjustbox` ép nhỏ font vì rộng hơn
  `\linewidth`. Đo chính xác bằng cách tạm bỏ `adjustbox` và đọc cảnh báo "Overfull \hbox (X pt too
  wide)" của pdflatex: Table 3 rộng hơn 197.7pt (\linewidth thật = 390pt, đo bằng file test riêng
  in `\the\linewidth`) → tỉ lệ ép ~66%; Table 4 rộng hơn 86.4pt → ép ~82%. Đây là bằng chứng thật,
  không phải ước lượng, cho thấy Table 3 bị ép nặng hơn nhiều.
  - **Xoay trục** cả 2 bảng (SR model thành cột, metric thành dòng) như Table 5, dùng cột
    `p{width}` cố định + `\centering` để các ô dài (tên model `swinir_classical`, verdict
    "significant gain", "Trained for: real-world degradation") tự xuống dòng thay vì kéo giãn cột.
  - Thử nghiệm nhiều độ rộng cột bằng file `.tex` test độc lập (đo lại overfull mỗi lần) để tìm
    độ rộng vừa đủ cho các ô ngắn (`77.9 ± 0.3`, `[+0.7, +2.0]`) nằm 1 dòng, chỉ ô dài thật sự
    (tên model, verdict) mới xuống dòng: Table 3 dùng `p{1.85cm}` × 5 cột (kết quả: overflow còn
    **7pt/390pt ≈ 1.8%**, gần như không bị ép); Table 4 dùng `p{1.68cm}` × 6 cột, thêm rút gọn
    "degradation" → "deg." trong dòng "Trained for" (kết quả: overflow còn **31.8pt/390pt ≈ 8%**).
    Cả 2 đều cải thiện rõ rệt so với ép gốc (66% và 82%).
  - Phát hiện phụ: hàm `tex()` có sẵn trong `make_paper_assets.py` đã tự chèn `\_\allowbreak{}`
    sau mọi dấu gạch dưới — nghĩa là tên model dài (`swinir_classical`) vốn đã có điểm ngắt dòng
    hợp lệ, không cần can thiệp thêm; chỉ cần cột đủ hẹp để buộc nó ngắt.
  - Sửa 2 hàm `tab_d1_main()` và `tab_d2()` trong `scripts/make_paper_assets.py` (nguồn sinh
    bảng) theo thiết kế đã đo đạc, cùng `pos="H"` (nhất quán với các bảng khác, tránh trôi
    section). Hand-patch `paper/generated/tab_d1_main.tex` và `tab_d2_fidelity.tex` theo đúng
    logic hàm mới (máy này không có `runs/` để chạy lại script thật) — chú ý dùng đúng
    `\_\allowbreak{}` khi hand-patch để khớp hành vi `tex()` thật.
  - Build lại PDF: 22→23 trang (bảng xoay trục cao hơn do nhiều dòng thuộc tính hơn, dự kiến).
    Quét lại toàn bộ heading + caption theo trang (như bước sửa float trôi trước đó) xác nhận
    Table 3/4 vẫn nằm đúng Section 3, không trôi. Verify trực quan bằng ảnh render: cả 2 bảng đọc
    rõ, chỉ ô tên model dài và verdict xuống 2 dòng, các ô số liệu ngắn nằm 1 dòng.
  - Không sync sang `sr4rec`, không cần chạy lại `pytest`. `ruff check` + `py_compile` trên
    `scripts/make_paper_assets.py` sau mỗi lần sửa đều sạch.

- [x] **Rà văn phong/câu cú toàn bài: tín hiệu AI-smell + từ/ý lặp lại** ✅ XONG (2026-09-29)
  Quét có hệ thống phần văn xuôi (Motivation → Conclusions, ~3000 từ thô, còn dư nhiều so với ngân
  sách 3600-3900/4000 từ) bằng grep + script đếm tần suất từ:
  - **Tín hiệu AI-smell kinh điển**: grep các cụm hay gặp ở văn AI-generated
    (`moreover/furthermore/leverage/delve/seamless/crucial/it is important to note/cutting-edge/
    paves the way/underscore/in order to/a wide range of/state-of-the-art` v.v.) — **không có cụm
    nào** xuất hiện trong bài. Cũng xác nhận lại không còn dấu vết tiết lộ AI (Claude/ChatGPT/...).
    Kết luận: các lượt sửa trước đó trong phiên đã dọn khá sạch phần này rồi, không cần sửa thêm.
  - **2 chỗ lặp ý thật** (không phải lặp từ đơn thuần mà lặp cả câu gần như nguyên văn, xác nhận
    bằng grep chính xác từng vị trí):
    1. Bộ ba "SR model là weights file / PyTorch class / folder of images" nhắc lại 3 lần gần như
       y nguyên (O2 dòng 238-239 tóm tắt ngắn; §2.2 "Three SR sources" dòng 298-300 giải thích đầy
       đủ; Impact dòng 534-536 lặp lại y hệt). Giữ nguyên bản tóm tắt ở O2 (giới thiệu lần đầu, tự
       nhiên) và bản đầy đủ ở §2.2 (nơi hợp lý nhất về mặt kỹ thuật), **rút gọn bản ở Impact** thành
       "SR models are inputs in whatever form a group already has them (Section~2.2)" — dẫn chéo
       thay vì liệt kê lại 3 dạng.
    2. Ý "hai model SwinIR chung kiến trúc → cô lập được yếu tố training degradation" nhắc lại 3
       lần (Experimental setup dòng 398-399; D1 dòng 411-412; D2 dòng 446 — lần thứ 3 tự dùng chữ
       "again" nhưng vẫn nhắc lại đầy đủ cơ chế, thừa). Giữ bản đầy đủ ở Experimental setup (nơi
       thiết lập thí nghiệm, hợp lý nhất), **rút gọn D1** thành mệnh đề phụ dẫn chéo ngược lại
       "(the two SwinIR variants share one architecture; see Experimental setup above)", **rút
       gọn D2** thành "again isolated by the SwinIR pair's shared architecture" (không lặp lại cả
       câu cơ chế nữa).
  - **1 điểm nhẹ hơn đã báo cáo nhưng không sửa** (theo lựa chọn phạm vi của người dùng): cụm "the
    same ___" xuất hiện 15 lần toàn bài — phần lớn hợp lý vì bài là paired-comparison (phải nói
    "same test images/same split/same run" nhiều), để nguyên.
  - Build lại PDF, verify bằng `pdftotext` cả 4 vị trí đã sửa đúng câu chữ mới, 23 trang không đổi,
    không phát sinh overfull mới (chỉ còn các cảnh báo nhỏ có sẵn từ trước, không liên quan).
  - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). Không cần chạy lại `pytest`/`ruff`
    (chỉ đổi văn bản LaTeX, không đổi code).
  - **Đọc lại đúng 3 câu vừa rút gọn** (theo yêu cầu tiếp theo của người dùng: "câu văn đã suôn
    chưa, đừng lủng củng") — phát hiện 3 chỗ đọc trúc trắc do rút gọn vội: (1) đoạn Impact "SR
    models are inputs in whatever form a group already has them" lặp chữ "group" 2 lần liền, sửa
    thành "It treats SR models as inputs of any kind..."; (2) đoạn D1 dùng "(...; see Experimental
    setup above)" — kiểu dẫn chiếu "above" không khớp văn phong dẫn chiếu bằng `Section~\ref{}`
    nhất quán trong bài, sửa thành 1 câu liền mạch "...since the two SwinIR variants otherwise
    share one architecture" (bỏ hẳn dẫn chiếu vì đoạn đó nằm ngay phía trên, không cần con trỏ);
    (3) đoạn D2 "again isolated by the SwinIR pair's shared architecture" là modifier treo ở cuối
    câu, chủ ngữ ngữ pháp không rõ ràng, sửa thành câu riêng "As in D1, the SwinIR pair's shared
    architecture places the cause in training degradation, not the network." (tránh lặp động từ
    "points" vốn vừa dùng ở câu trước đó).
  - **Rà lại cấu trúc bài so với yêu cầu SoftwareX** (không chỉ câu chữ): xác nhận lại — cấu trúc 5
    phần bắt buộc (Motivation and significance → Software description → Illustrative examples →
    Impact → Conclusions) đúng chuẩn; bảng Required Metadata đủ; Section 3 được đóng khung đúng là
    "minh hoạ phần mềm hoạt động" (câu mở đầu "The numbers in this section are produced by the
    demonstration configurations shipped with SR4Rec..." nêu rõ đây là demo có sẵn trong gói, tái
    lập được — không phải khoe phát hiện khoa học mới) chứ không đọc như "Results" của 1 bài
    nghiên cứu trá hình; kết quả âm tính (D2 không khác biệt có ý nghĩa) vẫn được giữ nguyên, đúng
    tinh thần trung thực khoa học SoftwareX khuyến khích. Không phát hiện vấn đề cấu trúc mới so
    với đánh giá reviewer đã làm đầu phiên.
  - Build lại PDF lần nữa, verify bằng `pdftotext` cả 3 câu sửa lần này đúng câu chữ, 23 trang
    không đổi, không lỗi mới.

- [x] **Đối chiếu số liệu văn xuôi ↔ bảng biểu — phát hiện 1 claim rộng hơn bảng, đã lấy dữ liệu**
  **thật để hoàn tất** ✅ XONG (2026-09-30)
  Đối chiếu tay từng con số trong Motivation→Conclusions với Table 1-6, C.1-C.2 và `macros.tex`.
  **Toàn bộ số liệu khác đều khớp chính xác** (Rank-1/Δ/CI/p/same-sign D1, PSNR/SSIM/Δ D2, verdict
  theo size bin, latency ranges, số ảnh/lớp/seed/giờ chạy, tổng 18.7 GPU-hours = 13.8+0.1+0.8+4.0
  cộng đúng tuyệt đối). Có 1 chỗ nhỏ (không phải lỗi): "SPAN adds 19 ms to a 14 ms ResNet-18" làm
  tròn 13.5→14, trong khi caption Table 6 ghi chính xác 13.5 — chấp nhận được, không sửa.
  - **Phát hiện thật**: câu "turns every significant gain into significant harm" (Abstract dòng
    127 + §3 "What the protocol changes") khẳng định rộng hơn Table 5 — bảng đó **chỉ hiện 1/4
    model** (SPAN, model ít bị hại nhất) cho protocol `fixed_recognizer`, không có bảng nào trong
    bài cho thấy cả 4 model.
  - Tự kiểm tra xem có dữ liệu thật cho cả 4 model không (người dùng hỏi "làm sao kiểm tra"): đọc
    `src/sr4rec/demos/d1_earvn_fixed.yaml` (cấu hình chạy — xác nhận cả 4 model SR đều được chạy,
    không chỉ SPAN) và `src/sr4rec/demos/expected/d1_earvn_fixed.yaml` (giá trị đã đóng băng từ 1
    lần chạy thật) — tính Δ so bicubic (77.91%): realesrgan −24.64pp, swinir_realworld −24.28pp,
    swinir_classical −5.39pp, span −4.22pp (khớp đúng −4.2 đang in ở Table 5). **Dữ liệu điểm cho
    cả 4 model là có thật**, tất cả đều giảm mạnh — ủng hộ claim "every ... harm" về mặt dấu/độ
    lớn, nhưng file này không có $p$/CI để chứng minh "significant" đúng quy tắc thống kê bài tự
    đặt ra (cần `stats.csv` của lần chạy thật, hiện không có trên máy Mac này).
  - Người dùng chọn hướng: lấy `stats.csv`/`predictions.csv` thật từ máy GPU rồi thêm 1 bảng phụ
    (không mềm hoá câu chữ). Đã chuẩn bị sẵn hạ tầng để làm ngay khi có dữ liệu:
    - Thêm hàm `tab_d1_fixed_main()` trong `scripts/make_paper_assets.py` (cùng thiết kế xoay trục
      như `tab_d1_main`: SR model thành cột, Rank-1/Δ/CI/p/same-sign/verdict thành dòng), nối vào
      `main()` (`if "d1_fixed" in runs: ... tab_d1_fixed_main(...)`).
    - Thêm `\generated{tab_d1_fixed_main.tex}{...}{tab:d1-fixed}` vào Appendix C (`main.tex`), có
      câu dẫn nhập; sửa đoạn "What the protocol changes" dẫn chiếu thêm `Table~\ref{tab:d1-fixed}`
      cho breakdown đầy đủ (không tự chèn số `-24.6pp` vào văn xuôi chính vì chưa xác minh
      significance — cố ý thận trọng, tránh tạo ra chính lỗi "văn khác bảng" đang cố sửa).
    - Verify: build PDF, bảng mới hiện đúng placeholder đỏ "Table C.3: Pending: D1 fixed_recognizer
      per-model breakdown..." (do chưa có `generated/tab_d1_fixed_main.tex` thật), tham chiếu
      `\ref{tab:d1-fixed}` resolve đúng (không lỗi "undefined"), 23 trang không đổi.
    - `ruff check` + `py_compile` trên `scripts/make_paper_assets.py` sạch.
  - **Đã hoàn tất trên labai217** (2026-09-30): `sr4rec reproduce d1_earvn_fixed` (chạy full, 1.5h)
    rồi `python scripts/make_paper_assets.py --d1-fixed runs/reproduce_d1_earvn_fixed_3` — xác
    nhận CLI tự in ra đúng: **cả 4 model đều "reduced Rank-1 accuracy significantly"**, SPAN ít bị
    hại nhất (−4.2pp), khớp đúng số đã đóng băng từ trước (77.91/53.27/72.52/53.63/73.69).
    - Sự cố phụ đã xử lý: (1) venv trên labai217 mất import `sr4rec` sau `git pull` — do editable
      install cũ trỏ sai thư mục, sửa bằng `pip install -e .` lại; (2) `git pull` bị chặn bởi 2 file
      chưa track/đã sửa cục bộ (`quickstart.yaml` sửa dở, `requirements.lock` chưa track) — đã diff
      xác nhận an toàn (dữ liệu giống hệt, chỉ khác format/đã có sẵn trên remote) trước khi
      `git checkout`/`mv` rồi mới pull, đúng kỷ luật diff-trước-khi-discard đã thiết lập từ trước;
      (3) chạy `make_paper_assets.py` chỉ với `--d1-fixed` (không kèm `--d1 --d2 --d3`) làm
      `macros.tex` bị ghi đè mất hết macro D1/D2/D3/Qual — kiểm tra bằng `grep DONEFIXED main.tex`
      xác nhận `main.tex` **không hề dùng** macro D1-fixed nào, nên chỉ cần bỏ qua `macros.tex` bị
      ghi đè (không commit), chỉ lấy đúng `tab_d1_fixed_main.tex` — không cần chạy lại toàn bộ.
    - Nhận nội dung `tab_d1_fixed_main.tex` thật qua chat (dán trực tiếp, không cần git), verify
      khớp tuyệt đối với `expected/d1_earvn_fixed.yaml`: cả 4 Δ đúng bằng Rank-1 trừ bicubic, cả 4
      CI không chứa 0, $p<0.001$, same sign 3/3, verdict "significant harm" cho cả 4 — xác nhận
      claim "every...harm" trong Abstract + §3 giờ có bằng chứng thật trong bài (Table C.3).
    - Cập nhật đoạn "What the protocol changes": thêm số cụ thể "$-4.2$\,pp cho SPAN (ít bị hại
      nhất) đến $-24.6$\,pp cho Real-ESRGAN (tệ nhất), cả 4 model Holm $p<0.001$", dẫn
      `Table~\ref{tab:d1-fixed}`.
    - Build lại PDF: 23→24 trang (Table C.3 thật thay placeholder), verify bằng `pdftotext` số
      liệu mới đúng, quét lại toàn bộ heading+caption theo trang xác nhận không float nào trôi
      sang sai section (kể cả sau khi thêm 1 trang mới). Không lỗi LaTeX mới.
    - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). Không cần chạy lại `pytest` (không
      đổi code core, chỉ thêm 1 hàm sinh bảng cho script paper-only).

- [x] **Đối chiếu toàn bộ góp ý `gop_y_sr4rec_softwarex.md` (Linh Do Nhat, 23 mục A1-A6/B1-B10,**
  **kiểm tại tag v0.1.1 28/09) với trạng thái thật repo `sr4rec` tag v0.1.2 + `paper/main.tex`**
  ✅ XONG (2026-09-30)
  Kiểm bằng công cụ đọc-only thật, không đoán từ trí nhớ: `git rev-parse v0.1.2^{commit}` xác
  nhận bản clone local `sr4rec` khớp tuyệt đối HEAD/`origin/main`; `curl` sống kiểm DOI/PyPI;
  `gh run list` kiểm workflow `Release`; grep/Read trực tiếp từng file được góp ý trích dẫn.
  **14/16 mục kiểm được đã đúng ("Đã sửa"), 1 mục hỏi lại người dùng (bỏ qua có chủ đích), chỉ
  2 mục thật sự còn sót và đã sửa ngay trong lượt này:**
  - ✅ A1 (PyPI install lỗi): xử lý bằng cách bỏ hẳn PyPI, cài `pip install -e .` từ repo clone
    (README + paper khớp nhau). `gh run list`: `Release` workflow trên commit v0.1.2 = success.
  - ✅ A2 (quickstart reproduce lỗi in làm minh hoạ): `quickstart.yaml` đã `frozen: true` với số
    thật; Appendix B transcript kết PASS.
  - ⚠️→✅ **A3 (3 chỗ ghi 3 version)**: C1/C2/pyproject/CITATION.cff/codemeta/.zenodo.json/
    reference_environment.md đều đã = 0.1.2 từ trước; chỉ sót **Appendix B transcript in
    `SR4Rec 0.1.0.dev0`** (dòng 664, 671) — đã sửa thành `SR4Rec 0.1.2` (xác nhận đúng format
    banner CLI thật qua `src/sr4rec/pipeline.py:554`).
  - ✅ A4 (reference_environment.md placeholder + tiếng Việt): đã điền đủ, không còn khối tiếng
    Việt (grep non-ASCII toàn repo chỉ khớp ký hiệu mũi tên/tam giác, không phải tiếng Việt).
  - ✅ A5 (CITATION.cff placeholder + tên sai): DOI concept đúng, tên Vinh tách đúng, ORCID đủ.
  - ✅ A6 (DOI chưa resolve): kiểm sống `curl` DOI mới (zenodo.23041108) → HTTP 302, resolve OK.
  - ⚠️→✅ **B1 (quy tắc verdict thiếu độ nhạy ngưỡng)**: 3/4 ý đã có sẵn (quy tắc tường minh,
    "Same sign" không phải điều kiện, cảnh báo D3 một seed); **thêm câu thứ 4** vào §2.2: "At the
    stricter $\alpha = 0.01$, every D1 verdict is unchanged, since all four Holm $p$ values are
    already below it." (tính từ $p$ đã in sẵn trong Bảng 3: 0.0018/$<$0.001/0.0044/0.0044, không
    cần chạy lại gì).
  - ✅ B2 (D3 "significant gain" không cảnh báo): Bảng 5 đã ghi "(1 seed)" + caption giải thích.
  - ✅ B3 (chữ "therefore" nối sai ở D2): đã viết lại, mạch logic đi qua D1.
  - ✅ B4 (dung sai rộng hơn hiệu ứng): đã có câu phân biệt "tolerances say whether the software
    reproduces its own numbers, not whether an SR model's effect... is real".
  - ✅ B5 (dependency chỉ chặn dưới): `requirements.lock` có thật, `ruff>=0.4,<0.17` đã chặn trên.
  - ⛔ **B6 (thiếu bảng S1-S8)**: hỏi người dùng — tiền đề gốc "phát hành qua PyPI" không còn
    đúng sau khi A1 bỏ hẳn PyPI, không có bản "executable" riêng để khai → **người dùng chọn
    không thêm**, giữ nguyên chỉ có bảng C1-C8.
  - ✅ B7 (nhãn C2 không nguyên văn template): đã đúng "Permanent GitHub link...".
  - ✅ B8 (Impact thiếu ý phổ biến + backbone): có đủ 3 câu hỏi mở; Limitations đã disclose rõ
    chỉ báo cáo ResNet-18.
  - ✅ B9 (abstract dài): đếm lại 134 từ (từ 177), gần mức EmbedKD (120)/bài mẫu (105).
  - ✅ B10 (D1 dùng dataset đồng tác giả): đã có nửa câu disclosure "published by a co-author".
  - Nhóm C (đã làm tốt theo góp ý): không kiểm lại, không có thay đổi nào trong phiên trước làm
    hỏng các điểm này.
  - Build lại PDF sau 2 chỗ sửa: 24 trang không đổi, không lỗi LaTeX mới. Verify bằng
    `pdftotext`: không còn `0.1.0.dev0`/`development version` nào trong bài; câu độ nhạy ngưỡng
    lên đúng chỗ, đúng nội dung.
  - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). Không cần chạy lại `pytest`/`ruff`
    (chỉ đổi 2 chuỗi + 1 câu văn LaTeX, không đổi code).

- [x] **Dọn sạch comment/ghi chú nội bộ + hạ tầng `\todo`/`\pending` khỏi `main.tex` (bản đã**
  **hoàn thiện, chuẩn bị gửi nhà xuất bản)** ✅ XONG (2026-09-30)
  Người dùng yêu cầu rà lại `main.tex` tìm dấu hiệu nội bộ/AI trước khi coi là sẵn sàng gửi nhà
  xuất bản. Rà bằng grep toàn bộ dòng `%...`, không có dấu vết Claude/ChatGPT/AI hay rò rỉ đường
  dẫn máy nội bộ (`software_x_tool`/`labai217`/`/root/...`) — sạch. Phát hiện 1 nhóm comment thật
  sự lộ quy trình soạn thảo nội bộ:
  - Khối đầu file: tự gọi bài là "(draft)", ghi chú build, câu "nothing is typed by hand", "Word
    budget per section is given in comments".
  - `% Draft helpers: remove \todo items before submission...` — tự nhắc rồi chính nó phải bị xoá.
  - **`%% 150-200 words. Write last (plan D5.2).`** — tham chiếu tới 1 tài liệu kế hoạch nội bộ
    kiểu mã ticket, cùng loại `B5.3`/`B1.9` đã bị gỡ khỏi repo `sr4rec` ở phiên trước.
  - 7 dòng `%% ---... N. TênMục (ngân sách từ)` đánh dấu ranh giới mỗi section kèm ngân sách từ
    tự đặt (`Motivation (750-850 words)`, `Software (1100-1200 words)`, v.v.) + 1 dòng tương tự
    cho "Declarations"/"Appendices" không kèm ngân sách.
  - 2 dòng toggle nội bộ đã comment (`% \usepackage{lineno}`, `% \linenumbers`).
  Theo yêu cầu "xoá hết vì bản đã hoàn thiện", đã xoá **toàn bộ** các dòng trên (không chỉ ẩn),
  đồng thời dọn luôn hạ tầng `\todo`/`\pending`/`\genfig` (macro không còn dùng đến vì mọi file
  `generated/*.tex` đã có dữ liệu thật, không còn khả năng "thiếu file" nữa):
  - Xoá định nghĩa `\todo`, `\pending`, `\genfig` (macro thứ 2 vốn không được gọi ở đâu cả — dead
    code từ đầu).
  - Đơn giản hoá `\generated` từ dạng có fallback đỏ "Pending: ..." xuống `\input{generated/#1}`
    thẳng — giữ nguyên chữ ký 3 tham số nên **không cần sửa 7 chỗ gọi** `\generated{...}{...}{...}`
    trong thân bài.
  - Đơn giản hoá dòng nạp `generated/macros.tex` từ `\IfFileExists{...}{...}{}` xuống `\input{...}`
    thẳng (không cần fallback rỗng nữa).
  - Xoá khối `\providecommand{\DONE...}{\todo{n}}` (7 dòng) — vô hại từ trước (macro thật đã ghi
    đè) nhưng là hạ tầng "phòng khi thiếu file" không còn cần khi bài đã chốt.
  - **Giữ nguyên** `\providecommand{\FloatBarrier}{\clearpage}` (dòng 8) — đây là fallback kỹ
    thuật chuẩn khi package `placeins.sty` không có sẵn trên máy build, không phải "todo" nội
    dung, thuộc loại thực hành LaTeX chuyên nghiệp bình thường, không đụng.
  - Build lại PDF: 24 trang không đổi, không lỗi LaTeX mới. `pdftotext` xác nhận **không còn chữ
    "TODO"/"Pending" nào** trong bản PDF cuối (kể cả trường hợp fallback lỡ kích hoạt).
  - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). Không cần chạy lại `pytest`/`ruff`
    (chỉ đổi LaTeX, không đổi code Python).

- [x] **Tối ưu khoảng trắng do ép `[H]` quá tay ở Section 3 (trang 9-14)** ✅ XONG (2026-09-30)
  Người dùng chỉ ra trang 11-12 trống gần nửa trang, thứ tự đoạn văn/bảng/hình chưa hợp lý. Xác
  nhận đúng nguyên nhân: lượt sửa "float trôi section" trước đó ép quá nhiều bảng/hình liên tiếp
  về `[H]` (đúng vị trí tuyệt đối, không co giãn) — hễ 1 float không đủ chỗ trên trang hiện tại là
  nhảy hẳn sang trang sau, để lại khoảng trắng lớn phía trên (đúng đánh đổi đã ghi chú trước "có
  thể để lại khoảng trắng nếu không đủ chỗ", nay xảy ra thật).
  - Trả về `[t]`/`[htbp]` (linh hoạt) cho: Figure 1 (architecture), Figure 4 (qualitative), và 4
    bảng sinh tự động Table 3/4/5/6 (`tab_d1_main`, `tab_d2_fidelity`, `tab_summary`,
    `tab_latency`) — sửa cả ở `scripts/make_paper_assets.py` (bỏ `pos="H"`) lẫn hand-patch 4 file
    `generated/*.tex` hiện có cho khớp.
    Bảng phụ lục C.1/C.2/C.3 (`tab_validation`, `tab_d1_by_size`, `tab_d1_fixed_main`) **giữ
    nguyên `[H]`** — không có bằng chứng lặp lại vấn đề ở đó, không đụng.
  - Thay vì ép từng float, chỉ chèn đúng 2 lệnh `\FloatBarrier` tại 2 ranh giới từng bị trôi
    (ngay trước `\subsection{Software functionalities}` và ngay trước `\section{Impact}`) — vẫn
    đảm bảo không trôi section (verify lại bằng đúng script quét heading+caption theo trang như
    các lần trước), nhưng cho LaTeX tự đóng gói khít nội dung *bên trong* mỗi ranh giới thay vì cấm
    hoàn toàn.
  - Build lại PDF (24 trang, không đổi), quét lại section/float: thứ tự vẫn đúng (Table 5+6 giờ
    nằm chung 1 trang trước "4. Impact", không tách rời như trước). Render ảnh so sánh trực quan
    nhiều trang: trang 9/10/11 giờ đặc kín chữ, không còn khoảng trắng lớn.
  - Còn sót 1 khoảng trắng ở cuối trang 12 (trước Figure 4) — không phải lỗi sắp xếp, do Figure 4
    cao gần hết trang (`0.78\textheight`, 4 hàng ảnh minh hoạ) nên không thể nhét vừa phần trang
    còn lại; đã báo người dùng, chưa quyết định có thu nhỏ figure hay để nguyên (giới hạn tự
    nhiên, không phải bug).
  - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). `ruff check` + `py_compile` trên
    `scripts/make_paper_assets.py` sạch. Không cần chạy lại `pytest`.

- [ ] **Đợt góp ý mới (4 mục) cho `paper/main.tex`** — 2/4 đã xong, 1 đang chờ dữ liệu thật, 1
  không cần sửa (2026-10-01)
  - ✅ **Mục 2 (requirements.lock không được nhắc)**: C6 (bảng metadata) chỉ ghi "dependencies in
    `pyproject.toml`", không nhắc `requirements.lock` dù file này có thật (87 gói ghim). Thêm câu
    theo đúng mẫu bài EmbedKD đã đăng ("The exact versions, operating system and driver that
    produced the published results are pinned in...") trỏ đúng `requirements.lock` +
    `docs/reference_environment.md` (tên file thật của SR4Rec, gạch dưới chứ không gạch ngang như
    bản EmbedKD).
  - ✅ **Mục 3 (câu "reference environment notes" không có đường dẫn)**: đoạn Reproduction, thêm
    `(\texttt{docs/reference\_environment.md})` ngay sau cụm đó.
  - ✅ **Mục 4 (dòng Reproducible Capsule trong bảng metadata)**: đã hỏi người dùng — **giữ nguyên
    C1-C8**, không thêm lại. Lý do: khớp tiền lệ bài EmbedKD thật đã đăng (cũng chỉ C1-C8); DOI
    vẫn còn đủ ở Data availability.
  - Build lại PDF, verify bằng `pdftotext`: cả 2 câu lên đúng, 24 trang không đổi, không lỗi mới.
  - ⏳ **Mục 1 (Appendix B transcript có version "0.1.2" nhưng tên thư mục run `2026-09-24`, sớm
    hơn ngày thật tạo tag v0.1.2 29/09)**: lỗi nội tại do sửa tay chuỗi version ở phiên trước mà
    không chạy lại thật. Khối `reproduce quickstart` bên dưới không bị lỗi này (tên thư mục cố
    định, không có ngày). Quyết định: không vá tay nữa, phải chạy lại thật toàn bộ trình tự `init`
    → `run --dry-run` → `run` → `reproduce quickstart` trên labai217 (đã cài v0.1.2), thay nguyên
    listing Appendix B bằng output thật mới. **Đang chờ người dùng chạy và gửi lại output.**
  - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). Không cần chạy lại `pytest`/`ruff`.

- [x] **Phát hiện + sửa tận gốc bug `__version__` gõ cứng, cắt tag `v0.1.3`, cập nhật bài báo**
  ✅ XONG phần code+tag+bài báo, ⏳ còn chờ Appendix B thật (2026-10-01)
  Khi chạy thật trình tự Appendix B trên labai217 (để lấy transcript thật thay bản sửa tay — mục 1
  đợt góp ý trước), phát hiện CLI vẫn in `SR4Rec 0.1.0.dev0` dù `pyproject.toml` ghi `0.1.2`. Lần
  theo mã nguồn: `src/sr4rec/__init__.py` dòng 8 có `__version__ = "0.1.0.dev0"` **gõ cứng, tách
  biệt hoàn toàn khỏi `pyproject.toml`** — đây mới là chuỗi thật được in ra mọi nơi (`--version`,
  log mỗi lần chạy, `fingerprint.yaml`, `report.md`, header file cấu hình sinh ra). Bug có **cả
  trong bản `sr4rec` công khai, ở đúng tag `v0.1.2` đã có DOI Zenodo** — ai clone đúng tag đó chạy
  lệnh cũng thấy sai. Vì tag đã có DOI (immutable), không thể sửa lại — quyết định **Hướng A**: sửa
  tận gốc rồi cắt tag mới `v0.1.3`.
  - Sửa `__version__` ở `src/sr4rec/__init__.py` (lỗi thật) + bump số hiệu đồng bộ ở
    `pyproject.toml`, `CITATION.cff`, `codemeta.json`, ở **cả 2 repo** (`software_x_tool` nguồn
    gốc, rồi đồng bộ tay sang `sr4rec`).
  - **Theo yêu cầu người dùng, mọi thao tác git/tag/release đều do người dùng tự tay làm** (tôi chỉ
    sửa file + đưa lệnh, không tự commit/push/tag/release).
  - CI fail ở lần push đầu (`Fix hardcoded version string; bump to 0.1.3`) — lý do thật: CI có bước
    chạy `python scripts/make_config_docs.py` rồi kiểm diff; vì `examples/configs/full_reference.yaml`
    là file sinh tự động có in version trong header, version đổi nên diff xuất hiện, file cũ chưa
    cập nhật. Xác nhận đúng cơ chế bằng cách tự chạy script đó thật (dùng `PYTHONPATH=src` trên Mac,
    không cần cài full package — `sr4rec/config_docs.py` chỉ cần `pydantic`/`pyyaml`, đã có sẵn),
    đúng 1 dòng đổi (`docs/config_reference.md` không đổi gì vì không in version). Đồng bộ đúng 1
    dòng đó sang `sr4rec`, verify `diff` 2 repo khớp tuyệt đối. Commit thứ 2
    (`Regenerate full_reference.yaml for v0.1.3`) → CI xanh.
  - Người dùng tự tag `v0.1.3`, publish Release (soạn sẵn note Fixed/ngắn gọn giúp người dùng dùng
    `gh release create` interactive, hướng dẫn từng bước UI). Zenodo tự archive, DOI mới:
    `10.5281/zenodo.23078036` (xác nhận sống qua `curl`, HTTP 302).
  - Cập nhật đúng 3 chỗ trong `paper/main.tex`: C1 (`v0.1.2`→`v0.1.3`), C2 (link
    `tree/v0.1.2`→`tree/v0.1.3`), Data availability (DOI `zenodo.23041108`→`zenodo.23078036`). Build
    lại PDF, verify bằng `pdftotext`: cả 3 đúng, không còn `v0.1.2`/DOI cũ, 24 trang không đổi.
  - ⏳ **Còn lại**: người dùng cần `git pull` + `pip install -e .` lại trên labai217 (nhận
    `__version__` đã sửa đúng), xác nhận `sr4rec --version` in đúng "SR4Rec 0.1.3", rồi chạy lại
    toàn bộ trình tự Appendix B thật, gửi output — tôi sẽ thay nguyên listing Appendix B (cắt bỏ
    tiền tố path tuyệt đối `/root/ThaiLe/...` về dạng tương đối) + build lại PDF lần cuối.
  - Không chạy lại `pytest` (không đổi logic code, chỉ version string + file sinh tự động); đã tự
    verify bằng cách chạy trực tiếp generator script, không cần mock.
  - ✅ **Hoàn tất (2026-10-01)**: người dùng `git pull` + `pip install -e .` lại trên labai217,
    `sr4rec --version` xác nhận đúng "SR4Rec 0.1.3", rồi chạy lại toàn bộ trình tự Appendix B thật
    (`init` → sửa `[CHECK]` → `run --dry-run` ×2 → `run` → `reproduce quickstart`). Output thật
    cho thấy: version in đúng "0.1.3" ở cả 2 lần chạy, tên thư mục run có ngày `2026-10-01` (hợp lý,
    sau ngày tạo tag v0.1.3), không còn nghịch lý ngày-tháng như bản cũ.
  - Đã thay nguyên khối `\begin{lstlisting}...\end{lstlisting}` trong Appendix B bằng output thật
    mới, với 2 điều chỉnh trình bày (đã báo người dùng trước khi làm):
    1. Cắt tiền tố path tuyệt đối `/root/ThaiLe/new_exprerient/software_x_tool/` về dạng tương đối
       (không lộ username/thư mục nội bộ server, khớp phong cách bản gốc).
    2. Bỏ 1 dòng cảnh báo `Warning: You are sending unauthenticated requests to the HF Hub...` —
       noise từ thư viện ngoài (huggingface_hub), không liên quan nội dung minh hoạ, không phải số
       liệu/kết quả của SR4Rec.
    Giữ nguyên tên thư mục `reproduce_quickstart_3` (số `_3` do máy đã chạy demo này vài lần trước
    trong phiên debug — output thật, không sửa cho "đẹp").
    Đoạn `reproduce quickstart` lần này không còn in các dòng "Downsampling.../SR bicubic.../SR
    tiny_espcn..." như bản cũ — vì SR outputs đã được cache từ lệnh `run` chạy ngay trước đó (đúng
    cơ chế cache theo content-hash đã mô tả trong Section 2 của bài, không phải thiếu sót).
  - Build lại PDF: 24→23 trang (giảm 1 trang vì transcript ngắn hơn, hợp lý). `pdftotext` xác nhận
    sạch hoàn toàn: không còn `0.1.0.dev0`, không còn `0.1.2`, không còn path `/root/ThaiLe/...`,
    không còn dòng HF Hub, ở bất kỳ đâu trong bài.
  - **Toàn bộ 2 đợt góp ý (gop_y_sr4rec_softwarex.md + đợt rà soát tiếp theo) giờ đã xử lý xong
    100%.**

- [x] **Rà layout lần cuối: chữ lòi lề phải (trang 12) + Listing 1 bị cắt ngang trang (trang 7-8)**
  ✅ XONG (2026-10-01)
  Người dùng tự đọc PDF phát hiện 2 lỗi trình bày:
  - Trang 12: `\texttt{docs/reference\_environment.md}` (thêm ở đợt góp ý trước, đoạn Reproduction)
    là 1 chuỗi monospace dài không có điểm ngắt dòng, tràn ra ngoài lề phải trang. Sửa bằng cách
    chèn `\allowbreak` sau dấu gạch dưới (`docs/reference\_\allowbreak{}environment.md`), đúng kỹ
    thuật đã dùng trong các bảng trước đó (`tex()` helper trong `make_paper_assets.py` cũng tự làm
    vậy cho tên model dài) — giờ ngắt gọn gàng thành 2 dòng, không tràn lề.
  - Trang 7-8: Listing 1 (ví dụ thêm SR model) bị tách đôi — caption + viền trên của khung code nằm
    lẻ loi ở cuối trang 7, phần thân code nhảy sang trang 8, nhìn rời rạc/gãy mạch. Thêm `\newpage`
    ngay trước `\begin{lstlisting}` để cả caption + khung code cùng sang trang 8 trọn vẹn.
  - Build lại PDF: vẫn 23 trang (không tăng, vì chỗ trống cuối trang 7 trước đó vốn đã lãng phí).
    Render ảnh trực tiếp từng trang xác nhận cả 2 chỗ đã đúng — Listing 1 liền mạch trên trang 8,
    dòng path ở trang 12 ngắt dòng gọn, không còn tràn lề.
  - Không sync sang `sr4rec` (paper/ ngoài phạm vi release). Không cần chạy lại `pytest`/`ruff`.

- [~] **Đợt góp ý thứ 3 (rà soát sau 2 đợt trước) + rà Guide for Authors SoftwareX** — ĐANG LÀM
  (2026-10-02). Kế hoạch đầy đủ: `~/.claude/plans/b-n-l-chuy-n-gia-synthetic-peacock.md`.
  Đã xong A1, A2, A3, A4, A8 (còn A5, A6, A7, A9, B1, B2):
  - **A1 (Abstract)**: câu "training on bicubic images only reversed every verdict" sai (chỉ 2/4
    model đổi dấu dưới `fixed_recognizer`, 2 model còn lại vốn đã harm thì chỉ harm nặng hơn, không
    "đảo dấu"). Sửa thành "...every SR model significantly harmed Rank-1" — đúng với Table
    `tab:d1-fixed` (cả 4 model đều `significant harm` dưới `fixed_recognizer`).
  - **A2 (Impact, đoạn 1)**: cùng lỗi logic ("...reversed when..."), sửa tương tự A1.
  - **A3 (Data availability)**: câu nói Zenodo chứa "recognizer checkpoints" sai — xác nhận qua
    Zenodo REST API record chỉ 195KB/1 file, không thể chứa checkpoint. Tách rõ: code+expected
    results ở Zenodo DOI; checkpoint thật phân phối qua GitHub Release assets, tải bằng
    `scripts/fetch_checkpoints.py` (đã có sẵn, xác nhận tồn tại trong `sr4rec` repo).
  - **A4 (README "one command")**: dòng 9 tự mâu thuẫn với dòng 50 "Three commands only" — sửa
    "one command" → "three commands". Sửa ở CẢ 2 repo: `software_x_tool/README.md` (nguồn thật) và
    `sr4rec/README.md` (bản release) — phát hiện cùng lỗi ở cả 2 nơi khi kiểm tra.
  - **A8 (references.bib)**: thêm `doi` cho 9 entry đã tra Crossref thật (liang2021swinir,
    wang2021realesrgan, wang2004ssim, deng2009imagenet, he2016resnet, howard2019mobilenetv3,
    liu2022convnext, parkhi2012pets, zhang2021bsrgan), kèm sửa 2 chỗ số trang lệch nhẹ
    (liu2022convnext: 11976--11986→11966--11976; zhang2021bsrgan: 4791--4800→4771--4780).
    paszke2019pytorch (NeurIPS) xác nhận thật sự không có DOI, không thêm.
  - Build lại PDF sạch, không lỗi mới. `pdftotext` xác nhận cả 3 câu sửa (A1/A2/A3) hiển thị đúng
    trong PDF cuối.
  - **Tự phát hiện thêm qua rà Guide for Authors SoftwareX (sciencedirect.com, WebSearch)**:
    Highlights là 1 file riêng bắt buộc (3-5 bullet, ≤85 ký tự/bullet, nộp cùng bản thảo, không
    nhúng vào PDF) — chưa có trong repo, lên kế hoạch A9 soạn nội dung. Đã hỏi người dùng về
    "Declaration of Generative AI and AI-assisted technologies" (chính sách Elsevier) — người dùng
    quyết định KHÔNG thêm.
  - **Table 4 Δ vs phép trừ tay (0.7 vs 0.8)**: người dùng hỏi đúng — Δ tính từ dữ liệu paired
    chưa làm tròn (`stats.py`, cùng số dùng để ra Verdict), không phải phép trừ 2 số Rank-1 đã làm
    tròn hiển thị. Đề xuất ban đầu "sửa Δ thành 0.7 cho khớp" bị từ chối đúng — sẽ là làm sai số
    liệu nghiên cứu thật (Δ không còn khớp với CI/p-value/Verdict phía sau). Quyết định cuối: KHÔNG
    đổi Δ, tăng Rank-1 lên 2 chữ số thập phân ở Table 4 (`fmt_mean_sd(..., digits=2)`, hàm đã có
    sẵn tham số này) để phép trừ tay khớp gần hơn, không cần thêm chú thích caption.
  - **A5 (Funding section)**: XONG. Elsevier bắt buộc, bài chưa có — thêm `\section*{Funding}`
    giữa "Declaration of competing interest" và "Data availability" với câu chuẩn ("This research
    did not receive any specific grant..."). Build lại PDF sạch, `pdftotext` xác nhận đúng vị trí.
  - **A9 (Highlights)**: XONG. Tạo `paper/highlights.txt` (5 bullet, 72-82 ký tự, đều ≤85) — file
    độc lập, KHÔNG `\input` vào `main.tex`, không ảnh hưởng PDF/DOI. Chỉ để copy sang hệ thống nộp
    bài (Editorial Manager) lúc submit; không liên quan tới Zenodo/GitHub release nên không cần
    tag/DOI mới.
  - **A7 (Figure 2 caption)**: XONG. Caption gốc chỉ nói "hollow markers are bins with fewer than
    50 test images (not tested)" mà không nói rõ D1 có bin nào như vậy không — gây hiểu lầm có thể
    có marker rỗng trong hình. Thêm vế "; none occur in D1." Build lại PDF sạch, `pdftotext` xác
    nhận đúng.
  - **B1 (Figure 3 label offset)**: sửa code xong, CHƯA regenerate PNG. `scripts/make_paper_assets.py`
    hàm `fig_d2_fidelity`: thêm dict `label_offset = {"swinir_classical": (5, 8), "span": (5,
    -10)}`, dùng `label_offset.get(m, (5, 3))` thay cho offset cố định `(5, 3)` cho mọi nhãn — 2
    model có PSNR/SSIM/Rank-1 gần nhau (35.66 vs 35.56 dB, 0.951 vs 0.949, 91.1 vs 90.9%) không còn
    đè nhãn lên nhau.
  - **B2 (Figure 4 fontsize)**: sửa code xong ở CẢ 2 repo, CHƯA regenerate PNG.
    `src/sr4rec/report/comparisons.py` (dùng chung với panel `comparisons/` thật của người dùng,
    không chỉ hình trong bài): `fontsize=7.5`→`9.5` (caption "pred:.../✓ correct" dưới mỗi ảnh),
    `fontsize=8.5`→`10` (title mỗi panel). Đã sync sang `sr4rec/src/sr4rec/report/comparisons.py`.
    `tests/test_report_format.py` pass sạch ở cả 2 repo (không có test assert fontsize cụ thể).
  - Còn lại: A6 (Rank-1 2 chữ số thập phân Table 4); B1/B2 cần người dùng chạy lại trên labai217
    (dữ liệu D2/D1 thật) để regenerate `fig_d2_fidelity.png`/`fig_d1_qualitative.png`, gửi PNG mới
    để thay vào `paper/figures/` và build PDF lần cuối.
