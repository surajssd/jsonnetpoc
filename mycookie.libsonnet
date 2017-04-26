local opencompose = import "lib/opencompose.libsonnet";
function(params={}, namespace="default")


opencompose.createServices(
{
  "database": {
    "image": "postgresql:latest",
    "ports": [
      {
        "expose": false,
        "name": "pg",
        "port": 5432
      }
    ]
  },
  "web": {
    "domain": "cookieapp.kubespray.com",
    "env": {
      "database": "postgres://postgres.default.svc"
    },
    "image": "quay.io/ant31/cookiapp:0.5.0",
    "ports": [
      {
        "name": "http",
        "port": 80
      }
    ]
  }
}
)
