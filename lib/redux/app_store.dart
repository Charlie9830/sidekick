import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:sidekick/redux/reducers/app_state_reducer.dart';
import 'package:sidekick/redux/state/app_state.dart';

final appStore = Store<AppState>(appStateReducer,
    initialState: AppState.initial(), middleware: [thunkMiddleware]);
