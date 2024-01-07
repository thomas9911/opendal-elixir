// direct copy paste from https://github.com/scrogson/franz/blob/master/native/franz/src/task.rs

use once_cell::sync::Lazy;
use std::future::Future;
use tokio::runtime::{Builder, Runtime};
use tokio::task::JoinHandle;

static TOKIO: Lazy<Runtime> = Lazy::new(|| {
    Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("OpenDAL.Native: Failed to start tokio runtime")
});

pub fn spawn<T>(task: T) -> JoinHandle<T::Output>
where
    T: Future + Send + 'static,
    T::Output: Send + 'static,
{
    TOKIO.spawn(task)
}

pub fn block_on<T>(task: T) -> T::Output
where
    T: Future + 'static,
    T::Output: Send + 'static,
{
    TOKIO.block_on(task)
}
