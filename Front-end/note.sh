# Biến CI_COMMIT_REF_NAME trong GitLab CI/CD có thể đại diện cho tên nhánh (branch), tên tag, hoặc tên commit ref (reference). Cụ thể:

# Nếu pipeline được kích hoạt từ một nhánh, CI_COMMIT_REF_NAME sẽ chứa tên của nhánh đó.
# Nếu pipeline được kích hoạt từ một tag, CI_COMMIT_REF_NAME sẽ chứa tên của tag đó.
# Nếu pipeline được kích hoạt từ một merge request, CI_COMMIT_REF_NAME sẽ chứa tên của nhánh nguồn của merge request đó.
# Điều này có nghĩa là CI_COMMIT_REF_NAME không chỉ đại diện cho commit mà còn có thể là tên của một nhánh hoặc tag tùy thuộc vào ngữ cảnh kích hoạt pipeline.

# Ví dụ:
# Khi bạn commit vào nhánh develop, CI_COMMIT_REF_NAME sẽ là develop.
# Khi bạn tạo một tag v1.0.0, CI_COMMIT_REF_NAME sẽ là v1.0.0.

stages:
  - build

build:
stage: build
before_script: - echo "$REGISTRY_PASS" | docker login -u "$REGISTRY_USER" --password-stdin $CI_REGISTRY
  script:
    - docker-compose build
    - docker image tag $PROJECT_NAME:$IMAGE_TAG $CI_REGISTRY/$PROJECT_NAME:$IMAGE_TAG
    - docker push $CI_REGISTRY/$PROJECT_NAME:$IMAGE_TAG
    - docker rmi $PROJECT_NAME:$IMAGE_TAG $CI_REGISTRY/$PROJECT_NAME:$IMAGE_TAG
  cache:
    key: "$CI_COMMIT_REF_NAME"
paths: - node_modules/
policy: push
expire_in: 1 week
rules: - if: '$CI_COMMIT_REF_NAME == "develop" || $CI_COMMIT_REF_NAME == "staging"'
    - if: '$CI_COMMIT_TAG == "true"' # Để kiểm tra nếu là tag

==================================================================
# Mô tả chung:
# Job clean-up: Là một công việc (job) trong GitLab CI/CD pipeline có nhiệm vụ dọn dẹp các tệp và Docker images không cần thiết.
# Stage clean-up: Công việc này thuộc giai đoạn (stage) có tên là clean-up.
# Script: Danh sách các lệnh sẽ được thực thi khi job chạy.
# Script chi tiết:
# Di chuyển đến thư mục chứa dữ liệu và xóa các tệp không cần thiết:

# yaml
# Sao chép mã

- cd $PATH_REGISTRY_PROJECT && ls -lt | grep "$CI_COMMIT_REF_NAME-_" | tail -n +4 | awk '{print $NF}' | xargs -I {} rm -rf {}

# cd $PATH_REGISTRY_PROJECT: Di chuyển đến thư mục được chỉ định bởi biến môi trường $PATH_REGISTRY_PROJECT.
# ls -lt: Liệt kê tất cả các tệp và thư mục trong thư mục hiện tại, sắp xếp từ mới đến cũ.
# **grep "$CI_COMMIT_REF_NAME-_": ** Lọc các tệp và thư mục có dạng <nhánh commit>-\*, trong đó CI_COMMIT_REF_NAME là tên nhánh hiện tại.
#   tail -n +4: Bỏ qua 3 dòng đầu tiên (tức là giữ lại các tệp và thư mục từ dòng thứ 4 trở đi).
#   awk '{print $NF}': In ra tên của các tệp và thư mục này.
#   **xargs -I {} rm -rf {}: \*\* Xóa tất cả các tệp và thư mục được liệt kê.
#   Kiểm tra và xóa các Docker images không cần thiết:

 Tạo một script shell để kiểm tra và xóa các Docker images:

yaml
Sao chép mã

- |
  cat << EOF > checkImages.sh
  !/bin/bash
  docker images $CI_REGISTRY/$PROJECT_NAME:$CI_COMMIT_REF_NAME-* --format '{{.Repository}}:{{.Tag}} {{.CreatedAt}}' | sort -k 2 -r | awk 'NR>2{print $1}' | xargs -r docker rmi
  echo "clean up done."
  EOF

cat << EOF > checkImages.sh: Tạo tệp checkImages.sh với nội dung được chèn vào bên trong EOF.
 docker images $CI_REGISTRY/$PROJECT_NAME:$CI_COMMIT_REF_NAME-_ --format '{{.Repository}}:{{.Tag}} {{.CreatedAt}}': Liệt kê các Docker images có tên dạng <tên image:tên nhánh-_> với định dạng {{.Repository}}:{{.Tag}} {{.CreatedAt}}.
  sort -k 2 -r: Sắp xếp các images theo thời gian tạo (từ mới đến cũ).
  awk 'NR>2{print $1}': Lấy danh sách các images từ dòng thứ 3 trở đi.
  xargs -r docker rmi: Xóa các images này.
  echo "clean up done.": In ra thông báo khi hoàn tất việc dọn dẹp.
  Sao chép script checkImages.sh lên máy chủ từ xa:

 yaml
 Sao chép mã

- scp checkImages.sh $SSH_USER@$SERVER_DEV:~/checkImages.sh
  scp checkImages.sh $SSH_USER@$SERVER_DEV:~/checkImages.sh: Sao chép tệp checkImages.sh từ máy local lên máy chủ từ xa (SERVER_DEV) trong thư mục home của người dùng (SSH_USER).
  Chạy script checkImages.sh trên máy chủ từ xa và xóa script sau khi hoàn thành:

yaml
Sao chép mã

- ssh $SSH_USER@$SERVER_DEV "chmod +x ~/checkImages.sh && ~/checkImages.sh && rm -rf ~/checkImages.sh"
  ssh $SSH_USER@$SERVER_DEV "chmod +x ~/checkImages.sh && ~/checkImages.sh && rm -rf ~/checkImages.sh": Kết nối SSH đến máy chủ từ xa (SERVER_DEV), gán quyền thực thi cho tệp checkImages.sh, chạy tệp checkImages.sh, và sau đó xóa tệp checkImages.sh.
