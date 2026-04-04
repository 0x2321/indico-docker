# 🚀 Indico Stack Example

This setup provides a full Indico environment for testing, including the Web server, PostgreSQL database, Redis, and Caddy as a reverse proxy.

### **Step 1: Configuration (The .env File)**

A `.env` file is provided in this folder to manage your environment variables.

*   **Indico Secret Key**: The `INDICO_SECRET_KEY` is mandatory for session security and session signing. You should generate a unique, long random string for this.
    *   **Generation command**:
        ```bash
        openssl rand -hex 32
        ```
*   **Base URL**: The `INDICO_BASE_URL` must match how you access the site (e.g., `http://localhost:8080/`). Ensure it includes the protocol and a trailing slash.

### **Step 2: Start the Stack**

To start all services, run:
```bash
docker compose up -d
```
The container's entrypoint automatically handles database initialization and migrations on the first run, so you don't need to manually set up the database schema.

### **Step 3: Access**

Once the containers are running, Indico is ready at **[http://localhost:8080/](http://localhost:8080/)**.
When you access the site for the first time, Indico will automatically detect that no administrator exists and will guide you through the initial setup wizard in your browser.


### **Advanced Configuration & Overrides** 📚

Indico's configuration in this container is split into two parts: an **automatically generated base** and your **custom overrides**.

*   **Core Configuration (Automatic)**:
    Settings like **Database Connection**, **Secret Key**, **Storage Paths**, and **Base URL** are automatically generated from your `.env` file. These are written into a protected section of the configuration that should not be edited manually.

*   **Custom Overrides (`indico.conf`)**:
    The file `./indico.conf` in this directory is mounted to `/etc/indico.conf` inside the container. It is intended for **additional** settings and feature toggles. Use this file for:
    *   📧 **SMTP / Email**: Configure your mail server for notifications.
    *   🔌 **Plugins**: Enable and configure Indico extensions.
    *   👤 **Authentication**: Set up LDAP, OAuth, or other identity providers.
    *   🎨 **Customization**: Adjust UI settings or localized defaults.

*   **Official Documentation**: For a complete list of all available settings you can add to your `indico.conf`, please refer to the [Official Indico Settings Documentation](https://docs.getindico.io/en/stable/config/settings/).

> Any setting defined in your custom `indico.conf` will take precedence over the automatically generated defaults.

### **Monitoring**

To monitor the status of your stack or troubleshoot issues, you can view the logs:
```bash
docker compose logs -f
```
