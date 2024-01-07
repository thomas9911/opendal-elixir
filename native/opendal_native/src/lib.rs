#![allow(non_snake_case)]

use std::{collections::HashMap, panic::AssertUnwindSafe};

use tokio::fs::File;

use opendal::Operator;
use opendal::{BlockingOperator, Scheme};
use rustler::{
    Encoder, JobSpawner, LocalPid, NifException, NifStruct, NifUnitEnum, OwnedEnv, ThreadSpawner, ResourceArc,
};

pub mod task;

#[derive(Debug, NifUnitEnum, Clone)]
#[non_exhaustive]
enum Service {
    Azblob,
    Dashmap,
    Fs,
    Http,
    Memory,
    Postgresql,
    Redis,
    S3,
}

impl Into<opendal::Scheme> for Service {
    fn into(self) -> Scheme {
        match self {
            Service::Azblob => Scheme::Azblob,
            Service::Dashmap => Scheme::Dashmap,
            Service::Fs => Scheme::Fs,
            Service::Http => Scheme::Http,
            Service::Memory => Scheme::Memory,
            Service::Postgresql => Scheme::Postgresql,
            Service::Redis => Scheme::Redis,
            Service::S3 => Scheme::S3,
        }
    }
}

#[derive(Debug, NifStruct, Clone)]
#[module = "OpenDAL.Config"]
struct Config {
    service: Service,
    options: HashMap<String, String>,
}

impl Config {
    fn into_blocking_operator(self) -> opendal::Result<BlockingOperator> {
        Ok(Operator::via_map(self.service.into(), self.options)?.blocking())
    }

    fn into_operator(self) -> opendal::Result<Operator> {
        Ok(Operator::via_map(self.service.into(), self.options)?)
    }
}

#[derive(Debug, NifException)]
#[module = "OpenDAL.Exception"]
struct Exception {
    message: String,
}

impl From<opendal::Error> for Exception {
    fn from(value: opendal::Error) -> Self {
        Exception {
            message: value.to_string(),
        }
    }
}

impl From<std::io::Error> for Exception {
    fn from(value: std::io::Error) -> Self {
        Exception {
            message: value.to_string(),
        }
    }
}


struct InnerConnection {
    operator: Operator
}

#[derive(NifStruct)]
#[module = "OpenDAL.Connection"]
struct Connection {
    inner: ResourceArc<InnerConnection>,
    config: Config,
}

#[rustler::nif]
fn init(config: Config) -> Result<Connection, Exception> {
    Ok(Connection{inner: ResourceArc::new(InnerConnection{operator: config.clone().into_operator()?}), config})
}

#[rustler::nif]
fn read(config: Connection, _path: &str) -> Result<(), Exception> {
    let _operator = config.config.into_blocking_operator().map_err(|e| Exception {
        message: e.to_string(),
    })?;

    Ok(())
}

#[rustler::nif]
fn read_into(
    conn: Connection,
    path: String,
    read_into_path: String,
    send_to: LocalPid,
) -> Result<(), Exception> {
    let inner_connection = AssertUnwindSafe(conn.inner.clone());
    
    ThreadSpawner::spawn(move || {
        task::block_on(async move {
            let result = inner_read_into(inner_connection.operator.clone(), path, read_into_path).await;

            let _ =
                OwnedEnv::new().send_and_clear(&send_to, |thread_env| result.encode(thread_env));
        });
    });

    Ok(())
}

async fn inner_read_into(operator: Operator, path: String, read_into_path: String) -> Result<(), Exception> {
    let mut reader = operator.reader(&path).await?;
    let mut file = File::create(read_into_path).await?;

    tokio::io::copy(&mut reader, &mut file).await?;

    Ok(())
}

#[rustler::nif]
fn write_from(
    conn: Connection,
    path: String,
    write_from_path: String,
    send_to: LocalPid,
) -> Result<(), Exception> {
    let inner_connection = AssertUnwindSafe(conn.inner.clone());


    ThreadSpawner::spawn(move || {
        task::block_on(async move {
            let result = inner_write_from(inner_connection.operator.clone(), path, write_from_path).await;

            let _ =
                OwnedEnv::new().send_and_clear(&send_to, |thread_env| result.encode(thread_env));
        });
    });

    Ok(())
}

async fn inner_write_from(
    operator: Operator,
    path: String,
    write_from_path: String,
) -> Result<(), Exception> {
    let mut writer = operator.writer(&path).await?;
    let mut file = File::open(write_from_path).await?;

    tokio::io::copy(&mut file, &mut writer).await?;
    writer.close().await?;

    Ok(())
}

rustler::init!("Elixir.OpenDAL.Native", [read, read_into, write_from, init], load = load);

fn load(env: rustler::Env, _: rustler::Term) -> bool {
    rustler::resource!(InnerConnection, env);

    true
}
