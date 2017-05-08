local opencompose = import "lib/opencompose.libsonnet";
function(params={}, namespace="default")

opencompose.createServices({
database: {
        image: "mariadb:10",
        env: {"MYSQL_ROOT_PASSWORD": "rootpasswd",
              "MYSQL_DATABASE": "wordpress",
              "MYSQL_USER": "wordpress",
              "MYSQL_PASSWORD": "wordpress"},
        ports: [{name: "dbport", port: 3306,}],
        mounts: [{name: "database", mount: "/var/lib/mysql"}],
    },

web: {
        image: "wordpress:4",
        env: {"WORDPRESS_DB_HOST": "database:3306",
              "WORDPRESS_DB_PASSWORD": "wordpress",
              "WORDPRESS_DB_USER": "wordpress",
              "WORDPRESS_DB_NAME": "wordpress"
        },
        ports: [{name: "wordpress", port: 80,}],
    },

})

