import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/database_service.dart';
import 'package:nojob/features/home/data/db_repo.dart';
import 'package:nojob/features/home/data/job_repo.dart';
import 'package:nojob/features/home/domain/ijob_repo.dart';
import 'package:nojob/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:nojob/features/home/presentation/viewmodels/line_chart_viewmodel.dart';
import 'package:nojob/features/logs/data/cookie_repo.dart';
import 'package:nojob/features/logs/presentation/viewmodels/cookie_viewmodel.dart';
import 'package:nojob/features/logs/presentation/viewmodels/log_viewmodel.dart';
import 'package:nojob/features/logs/presentation/viewmodels/search_viewmodel.dart';
import 'package:nojob/features/navigation/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:nojob/features/url_input/presentation/url_field_viewmodel.dart';
import 'package:nojob/shared/scrapper/scrapper_repo.dart';
import 'package:nojob/shared/scrapper/vacancy_scraper.dart';

// Repo
final dbService = Provider((ref) => DatabaseService());
final dbRepo = Provider<IDBRepo>((ref) => DBRepo(ref));
final jobRepo = Provider<IJobRepo>((ref) => JobRepo(ref));
final cookieRepo = Provider.autoDispose<ICookieRepo>(
  (ref) => CookieRepo(ref: ref),
);
final scrapperRepo = Provider.autoDispose<IScrapperRepo>(
  (ref) => ScrapperRepo(ref),
);
final vacancyScraper = Provider.autoDispose((ref) => CompositeVacancyScraper());

//ViewModels
final homeViewModel =
    AsyncNotifierProvider.autoDispose<HomeViewModel, HomeState>(
      HomeViewModel.new,
    );

final lineChartViewModel =
    AsyncNotifierProvider.autoDispose<LineChartViewModel, LineChartState>(
      LineChartViewModel.new,
    );

final urlFieldViewModel =
    AsyncNotifierProvider.autoDispose<UrlFieldViewModel, UrlFieldState>(
      UrlFieldViewModel.new,
    );

final logsViewModel =
    AsyncNotifierProvider.autoDispose<LogsViewModel, LogsState>(
      LogsViewModel.new,
    );

final cookieViewModel =
    NotifierProvider.autoDispose<CookieViewModel, CookieState>(
      CookieViewModel.new,
    );

final searchViewModel =
    AsyncNotifierProvider.autoDispose<SearchViewModel, LogsState>(
      SearchViewModel.new,
    );

final navigationViewModel =
    NotifierProvider.autoDispose<NavigationViewModel, AppScreen>(
      NavigationViewModel.new,
    );
