use std::path::PathBuf;

use anyhow::Result;

use clap::Parser;
use tracing::trace;
use tracing_subscriber::{EnvFilter, fmt, layer::SubscriberExt, util::SubscriberInitExt};

pub(crate) mod http;
pub(crate) mod nonogram;
pub(crate) mod ssh;

use http::{ROUTER, get_router};
use ssh::entrypoint;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct MainEntrypointArgs {
    /// SSH hostname.
    hostname: String,

    /// SSH port.
    #[arg(short, long, default_value_t = 22)]
    port: u16,

    /// SSH user to login as.
    #[arg(short, long, default_value_t = String::from(""))]
    login_name: String,

    /// Identity file containing private key.
    #[arg(short, long, value_name = "FILE")]
    identity_file: PathBuf,

    /// Remote hostname to bind to.
    #[arg(short = 'R', long, default_value_t = String::from(""))]
    remote_host: String,

    /// Remote port to bind to.
    #[arg(short = 'P', long, default_value_t = 80)]
    remote_port: u16,

    /// Request a pseudo-terminal to be allocated with the given command.
    #[arg(short = 't', long)]
    request_pty: Option<String>,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(EnvFilter::from_default_env())
        .init();
    trace!("Tracing is up!");

    rustls::crypto::aws_lc_rs::default_provider()
        .install_default()
        .expect("failed to install aws_lc_rs");

    let args = MainEntrypointArgs::parse();

    ROUTER.set(get_router().await).unwrap();

    entrypoint(
        args.hostname.as_str(),
        args.port,
        args.login_name.as_str(),
        args.identity_file,
        args.remote_host.as_str(),
        args.remote_port,
        args.request_pty,
    )
    .await
}
