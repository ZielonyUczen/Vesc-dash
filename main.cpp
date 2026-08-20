#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("VescDash");
    app.setApplicationName("VescDash");

    QQmlApplicationEngine engine;

    const QUrl url(QStringLiteral("qrc:/VescDash/qml/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [](const QUrl &objUrl) {
            qCritical() << "Failed to create QML object:" << objUrl;
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.loadFromModule("VescDash", "Main");

    return app.exec();
}
