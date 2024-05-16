## VPC

1. `vpc/secrets.auto.tfvars`ファイルを作成して、次のように記述する。

> [!WARNING]
> トレーニング用のユーザーやルートではないユーザーはこれらの情報を取得できないので、自分のルートユーザーからIAMを吐き出す。

```terraform
aws_access_key = "XXXXXXXXXXXXXXXXXXXXXX"
aws_secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```
