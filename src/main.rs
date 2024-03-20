#[macro_use] extern crate rocket;

use std::env;
use rocket::fs::FileServer;
use rocket_dyn_templates::{Template, context};

#[get("/health")]
fn health_check() -> &'static str {
    "Service up and running"
}

#[get("/")]
fn index() -> Template {
    Template::render(
        "index",
        context!{
            count: 0,
            is_dev: env::var("DEV").is_ok()
        }
    )
}

#[get("/<count>")]
fn increment_count(count: i32) -> Template {
    Template::render(
        "buttons",
        context!{
            count: count + 1
        }
    )
}

#[get("/reset")]
fn reset_count() -> Template {
    Template::render(
        "buttons",
        context!{
            count: 0
        }
    )
}


#[launch]
fn rocket() -> _ {
    rocket::build()
        .attach(Template::fairing())

        .mount("/public", FileServer::from("www/public"))
        .mount("/styles", FileServer::from("www/styles"))
        .mount("/scripts", FileServer::from("www/scripts"))

        .mount("/", routes![index, health_check])
        .mount("/count", routes![increment_count, reset_count])
}