{
	stdenv,
	runtimeShell,
	python3,
	python3Packages,
	fetchFromGitHub,
}:

let
	django-debug-toolbar = python3Packages.buildPythonPackage rec {
		pname = "django-debug-toolbar";
		version = "6.2.0";
		pyproject = true;
		src = fetchFromGitHub {
			owner = "django-commons";
			repo = "django-debug-toolbar";
			rev = "${version}";
			hash = "sha256-0NF71cuA55puEjJxd6I0xoeDQPWW+oxfWseDBmhis5k=";
		};
		
		build-system = with python3Packages; [
			hatchling
		];
		
		dependencies = with python3Packages; [
			django
			sqlparse
		];
	};
	django-select2 = python3Packages.buildPythonPackage rec {
		pname = "django-select2";
		version = "8.4.8";
		pyproject = true;
		src = fetchFromGitHub {
			owner = "codingjoe";
			repo = "django-select2";
			rev = "${version}";
			hash = "sha256-bY5pURtJD3gplFqIknAMEDpjtdQN25hLEaqBf+Wme7Q=";
		};
		
		build-system = with python3Packages; [
			flit-scm
		];
		
		dependencies = with python3Packages; [
			django
			django-appconf
		];
	};
	django-decorator-include = python3Packages.buildPythonPackage rec {
		pname = "django-decorator-include";
		version = "3.3";
		pyproject = true;
		src = fetchFromGitHub {
			owner = "twidi";
			repo = "django-decorator-include";
			rev = "${version}";
			hash = "sha256-lW/QdM9IPOrCLPPXrx4waBUaYi1OkM5Vd2uH8PZdWbs=";
		};
		
		build-system = with python3Packages; [
			flit-scm
		];
		
		dependencies = with python3Packages; [
			django
			django-appconf
		];
	};
	
	python = (python3.override {
		packageOverrides = final: prev: {
			inherit django-debug-toolbar django-select2 django-decorator-include;
		};
	}).withPackages (ps: with ps; [
		aiohttp
		apprise
		beautifulsoup4
		celery
		croniter
		defusedxml
		django
		django-allauth
		django-celery-beat
		django-celery-results
		django-debug-toolbar
		django-decorator-include
		django-health-check
		django-model-utils
		django-redis
		django-select2
		django-simple-history
		django-widget-tweaks
		gunicorn
		icalendar
		pillow
		psycopg
		python-decouple
		redis
		requests
		requests-ratelimiter
		unidecode
	]);
	pname = "yamtrack";
	version = "0.25.0";
	src = fetchFromGitHub {
		owner = "FuzzyGrim";
		repo = "Yamtrack";
		rev = "v${version}";
		hash = "sha256-dUf8ZVS1lWmP96G2KoPmqsRVypiCCvwtyOMhjEFPm1g=";
	};
in stdenv.mkDerivation (finalAttrs: {
	inherit pname version src;
	
	buildInputs = [
		python
	];
	
	buildPhase = ''
		runHook preBuild
		
		cd src
		python manage.py collectstatic --noinput
		
		runHook postBuild
	'';
	
	# TODO: is PUID and PGID needed?
	installPhase = ''
		runHook preInstall
		
		# Yamtrack assumes the database file (if sqlite is used) is relative to the application.
		# Since this is located in the read-only nix store, allow setting it via an environment variable.
		substituteInPlace config/settings.py \
			--replace-fail 'BASE_DIR / "db" / "db.sqlite3"' 'config("DB_FILE")'
		
		mkdir -p $out/lib
		cp -r . $out/lib/yamtrack
		
		mkdir -p $out/bin
		ln -s $out/lib/yamtrack/manage.py $out/bin/yamtrack-manage
		
		cat > $out/bin/yamtrack <<EOF
#!${runtimeShell}
cd $out/lib/yamtrack
${python.interpreter} manage.py migrate --noinput
${python}/bin/celery --app config worker --without-mingle --without-gossip &
${python}/bin/celery --app config beat &
exec ${python}/bin/gunicorn --config python:config.gunicorn config.wsgi:application
EOF
		
		chmod +x $out/bin/yamtrack
		
		runHook postInstall
	'';
	
	passthru = {
		inherit python;
		staticfiles = "${finalAttrs.finalPackage}/lib/yamtrack/staticfiles";
	};
	
	meta = {
		mainProgram = "yamtrack";
	};
})
