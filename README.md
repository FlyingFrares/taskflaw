# taskflaw

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FFlyingFrares%2Ftaskflaw.svg?type=shield&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2FFlyingFrares%2Ftaskflaw?ref=badge_shield&issueType=license)

The goal of this project is to build an infrastructure that follows the DevOps pipeline while incorporating Security (Sec) practices.
This includes:

- Containerization
- CI/CD Pipelines
- Deployment & Provisioning
- Security Testing
- Monitoring

![DevSecOps](https://images.contentstack.io/v3/assets/blt36c2e63521272fdc/bltd88a7a2bbf7463c7/63e6a271babb166bc7931cde/DevSecOps_Loop.png)

The Software used as the sandbox environment is a fork of the [tonimobin/cyber-security-base-2022](https://github.com/tonimobin/cyber-security-base-2022) repository.
It is a simple note/task Web App with basic CRUD functionalities, written in Python using Django framework.
This version has been intentionally modified to include several common security vulnerabilities found in Web Applications.
These flaws are based on the [OWASP Top 10](https://owasp.org/Top10/) list and are described in more detail below.

## Installation

1. Clone the repo
	`git clone https://github.com/FlyingFrares/taskflaw.git`
2. Create a virtual environment for Python:
	`python -m venv <venv>`
3. Activate the virtual environment:
	- On Windows:    
	    `<venv>\Scripts\activate`
	- On macOS/Linux:
	    `source <venv>/bin/activate` 
4. Install the packages from the `requirements.txt` file:
	`pip install -r requirements.txt`

## Docker

### Building and running your application

When you're ready, start your application by running:
`docker compose up --build`.

Your application will be available at http://localhost:8000.

## Usage

1. Start the server with the following command:
	`python3 manage.py runserver`
2. Go to `localhost:8000` in your browser and the application should be running (make sure other applications aren't running on port 8000)
3. Feel free to create a new user and some notes or use an existing user (Username: Joe, Password: JoePassword)
4. Go to `localhost:8000/admin` to enter Django administration (Username: admin, Password: admin)

## Flaw 1: [A01:2021 - Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)

###### Problem: 
In this application, it's currently possible to access notes of different users via URL modification. This is not desirable as if the data is sensitive, surely you wouldn't want random people accessing it. You could for example access the second note in the database via the following URL (even when not logged in on any user):

`http://localhost:8000/note/2/` 

###### Location: 
<https://github.com/FlyingFrares/taskflaw/blob/9b39b7766426e158e779cb672cd3142eb792b128/noteproject/notes/views.py#L69-L72>

###### Fix: 
To fix broken access control related issues, extra attention should be paid towards testing different views and making sure sensitive data is accessible only by suitable user groups. To fix the BAC issue in this software, you can restrict accessibility of the individual notes by, in this case, adding a `LoginRequiredMixin` to the class associated with the vulnerability - in this case the NoteDetail. After the edit, the class definition would look like this:

`class NoteDetail(LoginRequiredMixin, DetailView)`

This will limit the accessibility of the notes to authenticated users only.

## Flaw 2: [A02:2021 - Cryptographic Failures](https://owasp.org/Top10/A02_2021-Cryptographic_Failures/)

###### Problem:
In this application, during login process, the user data is transported without proper encryption (via HTTP) and the data contained in the POST method (username and password) can be hijacked. When the hijacker looks at the data, they'll see the username and password in plain text. In the picture below you can see a Wireshark capture, where the user 'User' logs in to the application. His password is 'UserPassword'. Both the username and the password can be seen in plain text.

![dump.png](images/dump.png)

###### Location: 
<https://github.com/FlyingFrares/taskflaw/blob/9b39b7766426e158e779cb672cd3142eb792b128/noteproject/notes/templates/notes/login.html#L7-L14>

###### Fix: 
It would be a good idea to use a more secure way of transportation, such as SSL or HTTPS. When using these, the data will be sent in encrypted format and if hijacked, the hijacker can't make sense of the data because they won't have the required key to decrypt the data.

More info [Here](https://docs.djangoproject.com/en/5.1/topics/security/#ssl-https).

## Flaw 3: [A03:2021 - Cross-Site Scripting (XSS)](https://cwe.mitre.org/data/definitions/79.html)

###### Problem: 
In this application, when creating a new incomplete note - the title field is not sanitized, which means it's possible to enter malicious code and have it execute when the new note is submitted. You could for example enter the following title and once you submit the note, an alert will pop up. Please note, that if you mark the note as complete, the script will not be executed as it will be rendered as a part of the note.

`Remember to buy pasta<script>alert('This could have been malicious code!');</script>.`

###### Location: 
<https://github.com/FlyingFrares/taskflaw/blob/9b39b7766426e158e779cb672cd3142eb792b128/noteproject/notes/templates/notes/note_list.html#L38-L41>

###### Fix: 
Using Django provided templates should protect you quite well, in this example the vulnerability was induced by the use of the safe-keyword. So be careful, if you use it. In this case, you can simply remove the safe pipe from line 38 and after the removal, the script will be processed as a string when submitted and thus no longer executable.

## Flaw 4: [A03:2021 - SQL Injection](https://owasp.org/Top10/A03_2021-Injection/)

###### Problem: 
The code uses a raw SQL query to filter notes based on the user's input in a search field. 
This approach can be risky because it directly interpolates user input into the SQL query, which can lead to SQL injection vulnerabilities. In this case, the search input is directly inserted into the query string without any sanitization or parameterization, making it possible for an attacker to manipulate the query by providing malicious input.

`' OR 1=1--.`

###### Location:
<https://github.com/FlyingFrares/taskflaw/blob/9b39b7766426e158e779cb672cd3142eb792b128/noteproject/notes/views.py#L58-L61>

###### Fix:
This can be fixed by using Django's ORM filtering methods instead of raw SQL queries.

``` python
context['notes'] = context['notes'].filter(
    title__startswith=search_input
)
```

## Flaw 5: [A04:2021 – Insecure Design](https://owasp.org/Top10/A04_2021-Insecure_Design/)

###### Problem: 
The Dockerfile does not specify a USER, creating a container which runs as root.
This is a security hazard. If an attacker can control a process running as root, they may have control over the container.

###### Location:
<https://github.com/FlyingFrares/taskflaw/blob/171bf0041b897c78aa31b5e5d51e03e55c07c42e/noteproject/Dockerfile#L19-L21>

###### Fix:
Create a non-privileged user inside Dockerfile that the app will run under.

``` dockerfile
RUN addgroup -g 1001 -S nonrootgroup && adduser -u 1001 -S nonroot -G nonrootgroup

USER nonroot
```

## Flaw 6: [A05:2021 - Security Misconfiguration](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)

###### Problem: 
In this app, the default settings are troublesome. The `SECRET_KEY` is left visible and `DEBUG`is `True` by default. Django itself warns about these issues as can be seen from the comments, but unfocused developers might forget to change these values. Secret keys should always be... secret. Debug is problematic in production, because it might reveal too much information about the inner workings of the system and simultaneously leak sensitive data or information.

The app also seemingly has password validation, but on closer inspection it is lacking. For example common passwords are not prevented and this makes the system susceptible to brute-force scripts that try to guess the password. The admin user has the password `admin`, which is extremely bad and should not be allowed.

###### Location: 
<https://github.com/FlyingFrares/taskflaw/blob/9b39b7766426e158e779cb672cd3142eb792b128/noteproject/noteproject/settings.py#L22-L26>

<https://github.com/FlyingFrares/taskflaw/blob/9b39b7766426e158e779cb672cd3142eb792b128/noteproject/noteproject/settings.py#L85-L98>

###### Fix: 
Make sure you're aware of the default settings and their pitfalls - react accordingly, in this case turn debug off in production and hide the secret key. Proper error handling is also necessary in order to avoid leaking sensitive information about the system. 

In regards to the password validation, improvement could be achieved by various different ways. One could create a filter based on [popular passwords](https://github.com/danielmiessler/SecLists/tree/master/Passwords). This filter would block the use of common passwords. Django also has its own common password validator, which could be implemented by adding the following to the code snippet shown above:

`{ 'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator' }`

## Flaw 7: [A06:2021 – Vulnerable and Outdated Components](https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components/)

###### Problem:
The application uses an outdated version of Django, which may contain known vulnerabilities that have been patched in newer versions. This can expose the application to security risks and attacks that exploit these vulnerabilities.

###### Location: 
<https://github.com/FlyingFrares/taskflaw/blob/3c1edc482050fa68d5347ab7d70f3add87483f95/noteproject/requirements.txt#L5>

###### Fix: 
Dependency-check can currently be used to scan software to identify the use of known vulnerable components.


## Flaw 8: [A09:2021 - Security Logging and Monitoring Failures](https://owasp.org/Top10/A09_2021-Security_Logging_and_Monitoring_Failures/)

###### Problem: 
In this software the logging has been disabled as can be seen below. If there was an attack such as the one described in Flaw #1 (a brute-force script that guesses passwords), there would be thousands if not hunders of thousands of logging attempts. When there is no logging, the system administrator is not aware of these logging attempts. If they became aware of these attempts, they'd know that they are under an attack and could then act accordingly. 

###### Location: 
<https://github.com/FlyingFrares/taskflaw/blob/9b39b7766426e158e779cb672cd3142eb792b128/noteproject/noteproject/settings.py#L124-L136>

###### Fix: 
In this software you could simply turn the `disable_existing_loggers` from `True` to `False` and you'd get some basic logging. Building a robust logging system is a more complex task that should be kept in mind throughout the development life cycle. Some core concepts that should kept in mind are unmodifiability of the logs, the intruder should not be able to modify the logs. Time stamps are vital as well, because with their aid it's possible to re-construct events and thus understand the causes and effects of different actions that have happened in the system. 
